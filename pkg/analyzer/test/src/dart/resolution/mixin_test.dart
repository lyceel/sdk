import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDriverResolutionTest);
    defineReflectiveTests(MixinTaskResolutionTest);
  });
}

@reflectiveTest
class MixinDriverResolutionTest extends DriverResolutionTest
    with MixinResolutionMixin {}

abstract class MixinResolutionMixin implements ResolutionTest {
  test_accessor_getter() async {
    addTestFile(r'''
mixin M {
  int get g => 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');

    var accessors = element.accessors;
    expect(accessors, hasLength(1));

    var gElement = accessors[0];
    assertElementName(gElement, 'g', offset: 20);

    var gNode = findNode.methodDeclaration('g =>');
    assertElement(gNode.name, gElement);

    var fields = element.fields;
    expect(fields, hasLength(1));
    assertElementName(fields[0], 'g', isSynthetic: true);
  }

  test_accessor_method() async {
    addTestFile(r'''
mixin M {
  void foo() {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');

    var methods = element.methods;
    expect(methods, hasLength(1));

    var fooElement = methods[0];
    assertElementName(fooElement, 'foo', offset: 17);

    var fooNode = findNode.methodDeclaration('foo()');
    assertElement(fooNode.name, fooElement);
  }

  test_accessor_setter() async {
    addTestFile(r'''
mixin M {
  void set s(int _) {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');

    var accessors = element.accessors;
    expect(accessors, hasLength(1));

    var sElement = accessors[0];
    assertElementName(sElement, 's=', offset: 21);

    var gNode = findNode.methodDeclaration('s(int _)');
    assertElement(gNode.name, sElement);

    var fields = element.fields;
    expect(fields, hasLength(1));
    assertElementName(fields[0], 's', isSynthetic: true);
  }

  test_commentReference() async {
    addTestFile(r'''
const a = 0;

/// Reference [a] in documentation.
mixin M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var aRef = findNode.commentReference('a]').identifier;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_element() async {
    addTestFile(r'''
mixin M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var mixin = findNode.mixin('mixin M');
    var element = findElement.mixin('M');
    assertElement(mixin, element);

    expect(element.typeParameters, isEmpty);
    assertElementTypes(element.superclassConstraints, [objectType]);
  }

  test_error_implementsClause_deferredClass() async {
    addTestFile(r'''
import 'dart:math' deferred as math;
mixin M implements math.Random {}
''');
    await resolveTestFile();
    var mathImport = findElement.import('dart:math');
    var randomElement = mathImport.importedLibrary.getType('Random');

    assertTestErrors([
      CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, [randomElement.type]);

    var typeRef = findNode.typeName('Random {}');
    assertTypeName(typeRef, randomElement, 'Random',
        expectedPrefix: mathImport.prefix);
  }

  test_error_implementsClause_disallowedClass_int() async {
    addTestFile(r'''
mixin M implements int {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, [intType]);

    var typeRef = findNode.typeName('int {}');
    assertTypeName(typeRef, intElement, 'int');
  }

  test_error_implementsClause_nonClass_void() async {
    addTestFile(r'''
mixin M implements void {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.IMPLEMENTS_NON_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, []);

    var typeRef = findNode.typeName('void {}');
    assertTypeName(typeRef, null, 'void');
  }

  test_error_onClause_deferredClass() async {
    addTestFile(r'''
import 'dart:math' deferred as math;
mixin M on math.Random {}
''');
    await resolveTestFile();
    var mathImport = findElement.import('dart:math');
    var randomElement = mathImport.importedLibrary.getType('Random');

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [randomElement.type]);

    var typeRef = findNode.typeName('Random {}');
    assertTypeName(typeRef, randomElement, 'Random',
        expectedPrefix: mathImport.prefix);
  }

  test_error_onClause_disallowedClass_int() async {
    addTestFile(r'''
mixin M on int {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [intType]);

    var typeRef = findNode.typeName('int {}');
    assertTypeName(typeRef, intElement, 'int');
  }

  test_error_onClause_nonClass_dynamic() async {
    addTestFile(r'''
mixin M on dynamic {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [objectType]);

    var typeRef = findNode.typeName('dynamic {}');
    assertTypeName(typeRef, dynamicElement, 'dynamic');
  }

  test_error_onClause_nonClass_enum() async {
    addTestFile(r'''
enum E {E1, E2, E3}
mixin M on E {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [objectType]);

    var typeRef = findNode.typeName('E {}');
    assertTypeName(typeRef, findElement.enum_('E'), 'E');
  }

  test_error_onClause_nonClass_void() async {
    addTestFile(r'''
mixin M on void {}
''');
    await resolveTestFile();

    assertTestErrors([
      CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_CLASS,
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [objectType]);

    var typeRef = findNode.typeName('void {}');
    assertTypeName(typeRef, null, 'void');
  }

  test_field() async {
    addTestFile(r'''
mixin M<T> {
  T f;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');

    var typeParameters = element.typeParameters;
    expect(typeParameters, hasLength(1));

    var tElement = typeParameters.single;
    assertElementName(tElement, 'T', offset: 8);
    assertEnclosingElement(tElement, element);

    var tNode = findNode.typeParameter('T> {');
    assertElement(tNode.name, tElement);

    var fields = element.fields;
    expect(fields, hasLength(1));

    var fElement = fields[0];
    assertElementName(fElement, 'f', offset: 17);
    assertEnclosingElement(fElement, element);

    var fNode = findNode.variableDeclaration('f;');
    assertElement(fNode.name, fElement);

    assertTypeName(findNode.typeName('T f'), tElement, 'T');

    var accessors = element.accessors;
    expect(accessors, hasLength(2));
    assertElementName(accessors[0], 'f', isSynthetic: true);
    assertElementName(accessors[1], 'f=', isSynthetic: true);
  }

  test_implementsClause() async {
    addTestFile(r'''
class A {}
class B {}

mixin M implements A, B {} // M
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, [
      findElement.interfaceType('A'),
      findElement.interfaceType('B'),
    ]);

    var aRef = findNode.typeName('A, ');
    assertTypeName(aRef, findElement.class_('A'), 'A');

    var bRef = findNode.typeName('B {} // M');
    assertTypeName(bRef, findElement.class_('B'), 'B');
  }

  test_metadata() async {
    addTestFile(r'''
const a = 0;

@a
mixin M {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var a = findElement.topGet('a');
    var element = findElement.mixin('M');

    var metadata = element.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].element, same(a));

    var annotation = findNode.annotation('@a');
    assertElement(annotation, a);
    expect(annotation.elementAnnotation, same(metadata[0]));
  }

  test_onClause() async {
    addTestFile(r'''
class A {}
class B {}

mixin M on A, B {} // M
''');
    await resolveTestFile();
    assertNoTestErrors();

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [
      findElement.interfaceType('A'),
      findElement.interfaceType('B'),
    ]);

    var aRef = findNode.typeName('A, ');
    assertTypeName(aRef, findElement.class_('A'), 'A');

    var bRef = findNode.typeName('B {} // M');
    assertTypeName(bRef, findElement.class_('B'), 'B');
  }
}

@reflectiveTest
class MixinTaskResolutionTest extends TaskResolutionTest
    with MixinResolutionMixin {}
