// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_loader;

import 'dart:async' show Future;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/ast.dart'
    show
        Arguments,
        BottomType,
        Class,
        Component,
        DartType,
        Expression,
        FunctionNode,
        InterfaceType,
        Library,
        LibraryDependency,
        ProcedureKind,
        Supertype;

import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, HandleAmbiguousSupertypes;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import '../../api_prototype/file_system.dart';

import '../../base/instrumentation.dart'
    show Instrumentation, InstrumentationValueLiteral;

import '../builder/builder.dart'
    show
        ClassBuilder,
        Declaration,
        EnumBuilder,
        FieldBuilder,
        LibraryBuilder,
        NamedTypeBuilder,
        TypeBuilder;

import '../combinator.dart';

import '../deprecated_problems.dart' show deprecated_inputError;

import '../export.dart' show Export;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        noLength,
        SummaryTemplate,
        Template,
        templateAmbiguousSupertypes,
        templateCyclicClassHierarchy,
        templateExtendingEnum,
        templateExtendingRestricted,
        templateIllegalMixin,
        templateIllegalMixinDueToConstructors,
        templateIllegalMixinDueToConstructorsCause,
        templateInternalProblemUriMissingScheme,
        templateSourceOutlineSummary;

import '../fasta_codes.dart' as fasta_codes;

import '../kernel/kernel_shadow_ast.dart'
    show ShadowClass, ShadowTypeInferenceEngine;

import '../kernel/kernel_builder.dart' show KernelProcedureBuilder;

import '../kernel/kernel_target.dart' show KernelTarget;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../loader.dart' show Loader;

import '../parser/class_member_parser.dart' show ClassMemberParser;

import '../parser.dart' show Parser, lengthForToken, offsetForToken;

import '../problems.dart' show internalProblem, unhandled;

import '../scanner.dart' show ErrorToken, ScannerResult, Token, scan;

import '../severity.dart' show Severity;

import '../type_inference/interface_resolver.dart' show InterfaceResolver;

import '../type_inference/type_inference_engine.dart' show TypeInferenceEngine;

import '../type_inference/type_inferrer.dart'
    show LegacyModeMixinInferrer, StrongModeMixinInferrer;

import 'diet_listener.dart' show DietListener;

import 'diet_parser.dart' show DietParser;

import 'outline_builder.dart' show OutlineBuilder;

import 'outline_listener.dart' show OutlineListener;

import 'source_class_builder.dart' show SourceClassBuilder;

import 'source_library_builder.dart' show SourceLibraryBuilder;

class SourceLoader<L> extends Loader<L> {
  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final Map<Uri, List<int>> sourceBytes = <Uri, List<int>>{};

  // Used when building directly to kernel.
  ClassHierarchy hierarchy;
  CoreTypes coreTypes;
  // Used when checking whether a return type of an async function is valid.
  DartType futureOfBottom;
  DartType iterableOfBottom;
  DartType streamOfBottom;

  @override
  TypeInferenceEngine typeInferenceEngine;

  InterfaceResolver interfaceResolver;

  Instrumentation instrumentation;

  List<ClassBuilder> orderedClasses;

  SourceLoader(this.fileSystem, this.includeComments, KernelTarget target)
      : super(target);

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      templateSourceOutlineSummary;

  Future<Token> tokenize(SourceLibraryBuilder library,
      {bool suppressLexicalErrors: false}) async {
    Uri uri = library.fileUri;
    if (uri == null) {
      return deprecated_inputError(
          library.uri, -1, "Not found: ${library.uri}.");
    } else if (!uri.hasScheme) {
      return internalProblem(
          templateInternalProblemUriMissingScheme.withArguments(uri),
          -1,
          library.uri);
    } else if (uri.scheme == SourceLibraryBuilder.MALFORMED_URI_SCHEME) {
      // Simulate empty file
      return null;
    }

    // Get the library text from the cache, or read from the file system.
    List<int> bytes = sourceBytes[uri];
    if (bytes == null) {
      try {
        List<int> rawBytes = await fileSystem.entityForUri(uri).readAsBytes();
        Uint8List zeroTerminatedBytes = new Uint8List(rawBytes.length + 1);
        zeroTerminatedBytes.setRange(0, rawBytes.length, rawBytes);
        bytes = zeroTerminatedBytes;
        sourceBytes[uri] = bytes;
        byteCount += rawBytes.length;
      } on FileSystemException catch (e) {
        return deprecated_inputError(uri, -1, e.message);
      }
    }

    ScannerResult result = scan(bytes, includeComments: includeComments);
    Token token = result.tokens;
    if (!suppressLexicalErrors) {
      List<int> source = getSource(bytes);
      target.addSourceInformation(library.fileUri, result.lineStarts, source);
    }
    while (token is ErrorToken) {
      if (!suppressLexicalErrors) {
        ErrorToken error = token;
        library.addCompileTimeError(error.assertionMessage,
            offsetForToken(token), lengthForToken(token), uri);
      }
      token = token.next;
    }
    return token;
  }

  List<int> getSource(List<int> bytes) {
    // bytes is 0-terminated. We don't want that included.
    if (bytes is Uint8List) {
      return new Uint8List.view(
          bytes.buffer, bytes.offsetInBytes, bytes.length - 1);
    }
    return bytes.sublist(0, bytes.length - 1);
  }

  Future<Null> buildOutline(SourceLibraryBuilder library) async {
    Token tokens = await tokenize(library);
    if (tokens == null) return;
    OutlineBuilder listener = new OutlineBuilder(library);
    new ClassMemberParser(listener).parseUnit(tokens);
  }

  Future<Null> buildBody(LibraryBuilder library) async {
    if (library is SourceLibraryBuilder) {
      // We tokenize source files twice to keep memory usage low. This is the
      // second time, and the first time was in [buildOutline] above. So this
      // time we suppress lexical errors.
      Token tokens = await tokenize(library, suppressLexicalErrors: true);
      if (tokens == null) return;

      DietListener listener = createDietListener(library);
      DietParser parser = new DietParser(listener);

      listener.currentUnit = library;
      parser.parseUnit(tokens);

      for (SourceLibraryBuilder part in library.parts) {
        if (part.partOfLibrary != library) {
          // Part was included in multiple libraries. Skip it here.
          continue;
        }
        Token tokens = await tokenize(part);
        if (tokens != null) {
          listener.currentUnit = part;
          listener.uri = part.fileUri;
          listener.partDirectiveIndex = 0;
          parser.parseUnit(tokens);
        }
      }
    }
  }

  Future<Expression> buildExpression(
      SourceLibraryBuilder library,
      String enclosingClass,
      bool isInstanceMember,
      FunctionNode parameters) async {
    Token token = await tokenize(library, suppressLexicalErrors: false);
    if (token == null) return null;
    DietListener dietListener = createDietListener(library);

    Declaration parent = library;
    if (enclosingClass != null) {
      Declaration cls =
          dietListener.memberScope.lookup(enclosingClass, -1, null);
      if (cls is ClassBuilder) {
        parent = cls;
        dietListener
          ..currentClass = cls
          ..memberScope = cls.scope.copyWithParent(
              dietListener.memberScope.withTypeVariables(cls.typeVariables),
              "debugExpression in $enclosingClass");
      }
    }
    KernelProcedureBuilder builder = new KernelProcedureBuilder(null, 0, null,
        "debugExpr", null, null, ProcedureKind.Method, library, 0, 0, -1, -1)
      ..parent = parent;
    BodyBuilder listener = dietListener.createListener(
        builder, dietListener.memberScope, isInstanceMember);

    return listener.parseSingleExpression(
        new Parser(listener), token, parameters);
  }

  KernelTarget get target => super.target;

  DietListener createDietListener(SourceLibraryBuilder library) {
    return new DietListener(library, hierarchy, coreTypes, typeInferenceEngine);
  }

  void resolveParts() {
    List<Uri> parts = <Uri>[];
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        if (sourceLibrary.isPart) {
          sourceLibrary.validatePart();
          parts.add(uri);
        } else {
          sourceLibrary.includeParts();
        }
      }
    });
    parts.forEach(builders.remove);
    ticker.logMs("Resolved parts");

    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        library.applyPatches();
      }
    });
    ticker.logMs("Applied patches");
  }

  void computeLibraryScopes() {
    Set<LibraryBuilder> exporters = new Set<LibraryBuilder>();
    Set<LibraryBuilder> exportees = new Set<LibraryBuilder>();
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        sourceLibrary.buildInitialScopes();
      }
      if (library.exporters.isNotEmpty) {
        exportees.add(library);
        for (Export exporter in library.exporters) {
          exporters.add(exporter.exporter);
        }
      }
    });
    Set<SourceLibraryBuilder> both = new Set<SourceLibraryBuilder>();
    for (LibraryBuilder exported in exportees) {
      if (exporters.contains(exported)) {
        both.add(exported);
      }
      for (Export export in exported.exporters) {
        exported.exportScope.forEach(export.addToExportScope);
      }
    }
    bool wasChanged = false;
    do {
      wasChanged = false;
      for (SourceLibraryBuilder exported in both) {
        for (Export export in exported.exporters) {
          exported.exportScope.forEach((String name, Declaration member) {
            if (export.addToExportScope(name, member)) {
              wasChanged = true;
            }
          });
        }
      }
    } while (wasChanged);
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        sourceLibrary.addImportsToScope();
      }
    });
    for (LibraryBuilder exportee in exportees) {
      // TODO(ahe): Change how we track exporters. Currently, when a library
      // (exporter) exports another library (exportee) we add a reference to
      // exporter to exportee. This creates a reference in the wrong direction
      // and can lead to memory leaks.
      exportee.exporters.clear();
    }
    for (var library in builders.values) {
      if (library is SourceLibraryBuilder) {
        OutlineListener outlineListener = library.outlineListener;
        if (outlineListener != null) {
          for (var import in library.imports) {
            storeCombinatorIdentifiersResolution(
                outlineListener, import.imported, import.combinators);
          }
          for (var export in library.exports) {
            storeCombinatorIdentifiersResolution(
                outlineListener, export.exported, export.combinators);
          }
        }
      }
    }
    ticker.logMs("Computed library scopes");
    // debugPrintExports();
  }

  void debugPrintExports() {
    // TODO(sigmund): should be `covarint SourceLibraryBuilder`.
    builders.forEach((Uri uri, dynamic l) {
      SourceLibraryBuilder library = l;
      Set<Declaration> members = new Set<Declaration>();
      library.forEach((String name, Declaration member) {
        while (member != null) {
          members.add(member);
          member = member.next;
        }
      });
      List<String> exports = <String>[];
      library.exportScope.forEach((String name, Declaration member) {
        while (member != null) {
          if (!members.contains(member)) {
            exports.add(name);
          }
          member = member.next;
        }
      });
      if (exports.isNotEmpty) {
        print("$uri exports $exports");
      }
    });
  }

  void resolveTypes() {
    int typeCount = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        typeCount += sourceLibrary.resolveTypes();
      }
    });
    ticker.logMs("Resolved $typeCount types");
  }

  void finishDeferredLoadTearoffs() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishDeferredLoadTearoffs();
      }
    });
    ticker.logMs("Finished deferred load tearoffs $count");
  }

  void finishNoSuchMethodForwarders() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishForwarders();
      }
    });
    ticker.logMs("Finished forwarders for $count procedures");
  }

  void resolveConstructors() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.resolveConstructors(null);
      }
    });
    ticker.logMs("Resolved $count constructors");
  }

  void finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType) {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishTypeVariables(object, dynamicType);
      }
    });
    ticker.logMs("Resolved $count type-variable bounds");
  }

  void computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder bottomType,
      ClassBuilder objectClass) {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count +=
            library.computeDefaultTypes(dynamicType, bottomType, objectClass);
      }
    });
    ticker.logMs("Computed default types for $count type variables");
  }

  void finishNativeMethods() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishNativeMethods();
      }
    });
    ticker.logMs("Finished $count native methods");
  }

  void finishPatchMethods() {
    int count = 0;
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        count += library.finishPatchMethods();
      }
    });
    ticker.logMs("Finished $count patch methods");
  }

  /// Returns all the supertypes (including interfaces) of [cls]
  /// transitively. Includes [cls].
  Set<ClassBuilder> allSupertypes(ClassBuilder cls) {
    int length = 0;
    Set<ClassBuilder> result = new Set<ClassBuilder>()..add(cls);
    while (length != result.length) {
      length = result.length;
      result.addAll(directSupertypes(result));
    }
    return result;
  }

  /// Returns the direct supertypes (including interface) of [classes]. A class
  /// from [classes] is only included if it is a supertype of one of the other
  /// classes in [classes].
  Set<ClassBuilder> directSupertypes(Iterable<ClassBuilder> classes) {
    Set<ClassBuilder> result = new Set<ClassBuilder>();
    for (ClassBuilder cls in classes) {
      target.addDirectSupertype(cls, result);
    }
    return result;
  }

  /// Computes a set of classes that may have cycles. The set is empty if there
  /// are no cycles. If the set isn't empty, it will include supertypes of
  /// classes with cycles, as well as the classes with cycles.
  ///
  /// It is assumed that [classes] is a transitive closure with respect to
  /// supertypes.
  Iterable<ClassBuilder> cyclicCandidates(Iterable<ClassBuilder> classes) {
    // The candidates are found by a fixed-point computation.
    //
    // On each iteration, the classes that have no supertypes in the input set
    // will be removed.
    //
    // If there are no cycles, eventually, the set will converge on Object, and
    // the next iteration will make the set empty (as Object has no
    // supertypes).
    //
    // On the other hand, if there is a cycle, the cycle will remain in the
    // set, and so will its supertypes, and eventually the input and output set
    // will have the same length.
    Iterable<ClassBuilder> input = const [];
    Iterable<ClassBuilder> output = classes;
    while (input.length != output.length) {
      input = output;
      output = directSupertypes(input);
    }
    return output;
  }

  void checkSemantics(List<SourceClassBuilder> classes) {
    Iterable<ClassBuilder> candidates = cyclicCandidates(classes);
    if (candidates.isNotEmpty) {
      Map<ClassBuilder, Set<ClassBuilder>> realCycles =
          <ClassBuilder, Set<ClassBuilder>>{};
      for (ClassBuilder cls in candidates) {
        Set<ClassBuilder> cycles = cyclicCandidates(allSupertypes(cls));
        if (cycles.isNotEmpty) {
          realCycles[cls] = cycles;
        }
      }
      Map<LocatedMessage, ClassBuilder> messages =
          <LocatedMessage, ClassBuilder>{};
      realCycles.forEach((ClassBuilder cls, Set<ClassBuilder> cycles) {
        target.breakCycle(cls);
        List<ClassBuilder> involved = <ClassBuilder>[];
        for (ClassBuilder cls in cycles) {
          if (realCycles.containsKey(cls)) {
            involved.add(cls);
          }
        }
        // Sort the class names alphabetically to ensure the order is stable.
        // TODO(ahe): It's possible that a better UX would be to sort the
        // classes based on walking the class hierarchy in breadth-first order.
        String involvedString = (involved
                .where((c) => c != cls)
                .map((c) => c.fullNameForErrors)
                .toList()
                  ..sort())
            .join("', '");
        messages[templateCyclicClassHierarchy
            .withArguments(cls.fullNameForErrors, involvedString)
            .withLocation(cls.fileUri, cls.charOffset, noLength)] = cls;
      });

      // Report all classes involved in a cycle, sorted to ensure stability as
      // [cyclicCandidates] is sensitive to if the platform (or other modules)
      // are included in [classes].
      for (LocatedMessage message in messages.keys.toList()..sort()) {
        messages[message].addCompileTimeError(
            message.messageObject, message.charOffset, message.length);
      }
    }
    ticker.logMs("Found cycles");
    Set<ClassBuilder> blackListedClasses = new Set<ClassBuilder>.from([
      coreLibrary["bool"],
      coreLibrary["int"],
      coreLibrary["num"],
      coreLibrary["double"],
      coreLibrary["String"],
      coreLibrary["Null"],
    ]);
    for (ClassBuilder cls in classes) {
      if (cls.library.loader != this) continue;
      Set<ClassBuilder> directSupertypes = new Set<ClassBuilder>();
      target.addDirectSupertype(cls, directSupertypes);
      for (ClassBuilder supertype in directSupertypes) {
        if (supertype is EnumBuilder) {
          cls.addCompileTimeError(
              templateExtendingEnum.withArguments(supertype.name),
              cls.charOffset,
              noLength);
        } else if (!cls.library.mayImplementRestrictedTypes &&
            blackListedClasses.contains(supertype)) {
          cls.addCompileTimeError(
              templateExtendingRestricted.withArguments(supertype.name),
              cls.charOffset,
              noLength);
        }
      }
      TypeBuilder mixedInType = cls.mixedInType;
      if (mixedInType != null) {
        bool isClassBuilder = false;
        if (mixedInType is NamedTypeBuilder) {
          var builder = mixedInType.declaration;
          if (builder is ClassBuilder) {
            isClassBuilder = true;
            for (Declaration constructory
                in builder.constructors.local.values) {
              if (constructory.isConstructor && !constructory.isSynthetic) {
                cls.addCompileTimeError(
                    templateIllegalMixinDueToConstructors
                        .withArguments(builder.fullNameForErrors),
                    cls.charOffset,
                    noLength,
                    context: [
                      templateIllegalMixinDueToConstructorsCause
                          .withArguments(builder.fullNameForErrors)
                          .withLocation(constructory.fileUri,
                              constructory.charOffset, noLength)
                    ]);
              }
            }
          }
        }
        if (!isClassBuilder) {
          cls.addCompileTimeError(
              templateIllegalMixin.withArguments(mixedInType.fullNameForErrors),
              cls.charOffset,
              noLength);
        }
      }
    }
    ticker.logMs("Checked restricted supertypes");
  }

  void buildComponent() {
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        SourceLibraryBuilder sourceLibrary = library;
        L target = sourceLibrary.build(coreLibrary);
        if (!library.isPatch) {
          libraries.add(target);
        }
      }
    });
    ticker.logMs("Built component");
  }

  Component computeFullComponent() {
    Set<Library> libraries = new Set<Library>();
    List<Library> workList = <Library>[];
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (!library.isPart &&
          !library.isPatch &&
          (library.loader == this || library.fileUri.scheme == "dart")) {
        if (libraries.add(library.target)) {
          workList.add(library.target);
        }
      }
    });
    while (workList.isNotEmpty) {
      Library library = workList.removeLast();
      for (LibraryDependency dependency in library.dependencies) {
        if (libraries.add(dependency.targetLibrary)) {
          workList.add(dependency.targetLibrary);
        }
      }
    }
    return new Component()..libraries.addAll(libraries);
  }

  void computeHierarchy() {
    List<List> ambiguousTypesRecords = [];
    HandleAmbiguousSupertypes onAmbiguousSupertypes =
        (Class cls, Supertype a, Supertype b) {
      if (ambiguousTypesRecords != null) {
        ambiguousTypesRecords.add([cls, a, b]);
      }
    };
    if (hierarchy == null) {
      hierarchy = new ClassHierarchy(computeFullComponent(),
          onAmbiguousSupertypes: onAmbiguousSupertypes,
          mixinInferrer: target.strongMode
              ? new StrongModeMixinInferrer(this)
              : new LegacyModeMixinInferrer());
    } else {
      hierarchy.onAmbiguousSupertypes = onAmbiguousSupertypes;
      Component component = computeFullComponent();
      hierarchy.applyTreeChanges(const [], component.libraries,
          reissueAmbiguousSupertypesFor: component);
    }
    for (List record in ambiguousTypesRecords) {
      handleAmbiguousSupertypes(record[0], record[1], record[2]);
    }
    ambiguousTypesRecords = null;
    ticker.logMs("Computed class hierarchy");
  }

  void handleAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {
    String name = cls.name;
    TypeEnvironment env = new TypeEnvironment(coreTypes, hierarchy,
        strongMode: target.strongMode);

    if (cls.isAnonymousMixin) return;

    if (env.isSubtypeOf(a.asInterfaceType, b.asInterfaceType)) return;
    addProblem(
        templateAmbiguousSupertypes.withArguments(
            name, a.asInterfaceType, b.asInterfaceType),
        cls.fileOffset,
        noLength,
        cls.fileUri);
  }

  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}

  void computeCoreTypes(Component component) {
    coreTypes = new CoreTypes(component);

    futureOfBottom = new InterfaceType(
        coreTypes.futureClass, <DartType>[const BottomType()]);
    iterableOfBottom = new InterfaceType(
        coreTypes.iterableClass, <DartType>[const BottomType()]);
    streamOfBottom = new InterfaceType(
        coreTypes.streamClass, <DartType>[const BottomType()]);

    ticker.logMs("Computed core types");
  }

  void checkSupertypes(List<SourceClassBuilder> sourceClasses) {
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this) {
        builder.checkSupertypes(coreTypes);
      }
    }
    ticker.logMs("Checked overrides");
  }

  void checkOverrides(List<SourceClassBuilder> sourceClasses) {
    assert(hierarchy != null);
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this) {
        builder.checkOverrides(
            hierarchy, typeInferenceEngine?.typeSchemaEnvironment);
      }
    }
    ticker.logMs("Checked overrides");
  }

  void checkAbstractMembers(List<SourceClassBuilder> sourceClasses) {
    if (!target.strongMode) return;
    assert(hierarchy != null);
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this) {
        builder.checkAbstractMembers(coreTypes, hierarchy);
      }
    }
    ticker.logMs("Checked abstract members");
  }

  void addNoSuchMethodForwarders(List<SourceClassBuilder> sourceClasses) {
    if (!target.backendTarget.enableNoSuchMethodForwarders) return;

    List<Class> changedClasses = new List<Class>();
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.library.loader == this) {
        if (builder.addNoSuchMethodForwarders(target, hierarchy)) {
          changedClasses.add(builder.target);
        }
      }
    }
    hierarchy.applyMemberChanges(changedClasses, findDescendants: true);
    ticker.logMs("Added noSuchMethod forwarders");
  }

  void createTypeInferenceEngine() {
    typeInferenceEngine =
        new ShadowTypeInferenceEngine(instrumentation, target.strongMode);
  }

  void performTopLevelInference(List<SourceClassBuilder> sourceClasses) {
    if (target.disableTypeInference) return;

    /// The first phase of top level initializer inference, which consists of
    /// creating kernel objects for all fields and top level variables that
    /// might be subject to type inference, and records dependencies between
    /// them.
    typeInferenceEngine.prepareTopLevel(coreTypes, hierarchy);
    interfaceResolver = new InterfaceResolver(
        typeInferenceEngine,
        typeInferenceEngine.typeSchemaEnvironment,
        instrumentation,
        target.strongMode);
    builders.forEach((Uri uri, LibraryBuilder library) {
      if (library.loader == this) {
        library.forEach((String name, Declaration member) {
          if (member is FieldBuilder) {
            member.prepareTopLevelInference();
          }
        });
      }
    });
    {
      // Note: we need to create a list before iterating, since calling
      // builder.prepareTopLevelInference causes further class hierarchy
      // queries to be made which would otherwise result in a concurrent
      // modification exception.
      List<Class> classes = new List<Class>(sourceClasses.length);
      for (int i = 0; i < sourceClasses.length; i++) {
        classes[i] = sourceClasses[i].target;
      }
      orderedClasses = null;
      List<ClassBuilder> result = new List<ClassBuilder>(sourceClasses.length);
      int i = 0;
      for (Class cls
          in new List<Class>.from(hierarchy.getOrderedClasses(classes))) {
        result[i++] = ShadowClass.getClassInferenceInfo(cls).builder
          ..prepareTopLevelInference();
      }
      orderedClasses = result;
    }
    typeInferenceEngine.isTypeInferencePrepared = true;
    ticker.logMs("Prepared top level inference");

    /// The second phase of top level initializer inference, which is to visit
    /// fields and top level variables in topologically-sorted order and assign
    /// their types.
    typeInferenceEngine.finishTopLevelFields();
    List<Class> changedClasses = new List<Class>();
    for (var builder in orderedClasses) {
      ShadowClass class_ = builder.target;
      int memberCount = class_.fields.length +
          class_.constructors.length +
          class_.procedures.length +
          class_.redirectingFactoryConstructors.length;
      class_.finalizeCovariance(interfaceResolver);
      ShadowClass.clearClassInferenceInfo(class_);
      int newMemberCount = class_.fields.length +
          class_.constructors.length +
          class_.procedures.length +
          class_.redirectingFactoryConstructors.length;
      if (newMemberCount != memberCount) {
        // The inference potentially adds new members (but doesn't otherwise
        // change the classes), so if the member count has changed we need to
        // update the class in the class hierarchy.
        changedClasses.add(class_);
      }
    }

    orderedClasses = null;
    typeInferenceEngine.finishTopLevelInitializingFormals();
    if (instrumentation != null) {
      builders.forEach((Uri uri, LibraryBuilder library) {
        if (library.loader == this) {
          library.instrumentTopLevelInference(instrumentation);
        }
      });
    }
    interfaceResolver = null;
    // Since finalization of covariance may have added forwarding stubs, we need
    // to recompute the class hierarchy so that method compilation will properly
    // target those forwarding stubs.
    hierarchy.onAmbiguousSupertypes = ignoreAmbiguousSupertypes;
    hierarchy.applyMemberChanges(changedClasses, findDescendants: true);
    ticker.logMs("Performed top level inference");
  }

  Expression instantiateInvocation(Expression receiver, String name,
      Arguments arguments, int offset, bool isSuper) {
    return target.backendTarget.instantiateInvocation(
        coreTypes, receiver, name, arguments, offset, isSuper);
  }

  Expression instantiateNoSuchMethodError(
      Expression receiver, String name, Arguments arguments, int offset,
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false}) {
    return target.backendTarget.instantiateNoSuchMethodError(
        coreTypes, receiver, name, arguments, offset,
        isMethod: isMethod,
        isGetter: isGetter,
        isSetter: isSetter,
        isField: isField,
        isLocalVariable: isLocalVariable,
        isDynamic: isDynamic,
        isSuper: isSuper,
        isStatic: isStatic,
        isConstructor: isConstructor,
        isTopLevel: isTopLevel);
  }

  Expression throwCompileConstantError(Expression error) {
    return target.backendTarget.throwCompileConstantError(coreTypes, error);
  }

  Expression buildCompileTimeError(
      Message message, int offset, int length, Uri uri) {
    String text = target.context
        .format(message.withLocation(uri, offset, length), Severity.error);
    return target.backendTarget.buildCompileTimeError(coreTypes, text, offset);
  }

  void recordMessage(Severity severity, Message message, int charOffset,
      int length, Uri fileUri,
      {List<LocatedMessage> context}) {
    if (instrumentation == null) return;

    if (charOffset == -1 &&
        (message.code == fasta_codes.codeConstConstructorWithBody ||
            message.code == fasta_codes.codeConstructorNotFound ||
            message.code == fasta_codes.codeSuperclassHasNoDefaultConstructor ||
            message.code == fasta_codes.codeTypeArgumentsOnTypeVariable ||
            message.code == fasta_codes.codeUnspecified)) {
      // TODO(ahe): All warnings should have a charOffset, but currently, some
      // warnings lack them.
      return;
    }

    String severityString;
    switch (severity) {
      case Severity.error:
        severityString = "error";
        break;

      case Severity.internalProblem:
        severityString = "internal problem";
        break;

      case Severity.warning:
        severityString = "warning";
        break;

      case Severity.errorLegacyWarning:
        // Should have been resolved to either error or warning at this point.
        // Use a property name expressing that, in case it slips through.
        severityString = "unresolved severity";
        break;

      case Severity.context:
        severityString = "context";
        break;

      case Severity.ignored:
        unhandled("IGNORED", "recordMessage", charOffset, fileUri);
        return;
    }
    instrumentation.record(
        fileUri,
        charOffset,
        severityString,
        // TODO(ahe): Should I add an InstrumentationValue for Message?
        new InstrumentationValueLiteral(message.code.name));
    if (context != null) {
      for (LocatedMessage contextMessage in context) {
        instrumentation.record(
            contextMessage.uri,
            contextMessage.charOffset,
            "context",
            new InstrumentationValueLiteral(contextMessage.code.name));
      }
    }
  }

  void releaseAncillaryResources() {
    hierarchy = null;
    typeInferenceEngine = null;
  }

  void storeCombinatorIdentifiersResolution(OutlineListener outlineListener,
      LibraryBuilder consumed, List<Combinator> combinators) {
    if (combinators != null) {
      for (var combinator in combinators) {
        for (var identifier in combinator.identifiers) {
          var declaration = consumed.exportScope.local[identifier.name];
          declaration ??= consumed.exportScope.setters[identifier.name];
          outlineListener.store(identifier.offset, identifier.isSynthetic,
              isNamespaceCombinatorReference: true,
              reference: declaration?.target);
        }
      }
    }
  }
}
