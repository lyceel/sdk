// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/frontend_strategy.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/universe/feature.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:compiler/src/universe/world_impact.dart';
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const ImpactDataComputer(),
        args: args, skipForStrong: ['fallthrough.dart'], testFrontend: true);
  });
}

class Tags {
  static const String typeUse = 'type';
  static const String staticUse = 'static';
  static const String dynamicUse = 'dynamic';
  static const String constantUse = 'constant';
  static const String runtimeTypeUse = 'runtimeType';
}

class ImpactDataComputer extends DataComputer {
  const ImpactDataComputer();

  @override
  void setup() {
    ImpactCacheDeleter.retainCachesForTesting = true;
  }

  @override
  void computeMemberData(
      Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
      {bool verbose: false}) {
    KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
    WorldImpact impact = compiler.impactCache[member];
    MemberDefinition definition =
        frontendStrategy.elementMap.getMemberDefinition(member);
    Features features = new Features();
    if (impact.typeUses.length > 50) {
      features.addElement(Tags.typeUse, '*');
    } else {
      for (TypeUse use in impact.typeUses) {
        features.addElement(Tags.typeUse, use.shortText);
      }
    }
    if (impact.staticUses.length > 50) {
      features.addElement(Tags.staticUse, '*');
    } else {
      for (StaticUse use in impact.staticUses) {
        features.addElement(Tags.staticUse, use.shortText);
      }
    }
    for (DynamicUse use in impact.dynamicUses) {
      features.addElement(Tags.dynamicUse, use.shortText);
    }
    for (ConstantUse use in impact.constantUses) {
      features.addElement(Tags.constantUse, use.shortText);
    }
    if (impact is TransformedWorldImpact &&
        impact.worldImpact is ResolutionImpact) {
      ResolutionImpact resolutionImpact = impact.worldImpact;
      for (RuntimeTypeUse use in resolutionImpact.runtimeTypeUses) {
        features.addElement(Tags.runtimeTypeUse, use.shortText);
      }
    }
    Id id = computeEntityId(definition.node);
    actualMap[id] = new ActualData(new IdValue(id, features.getText()),
        computeSourceSpanFromTreeNode(definition.node), member);
  }
}
