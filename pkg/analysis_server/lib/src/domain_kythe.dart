// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analysis_server/src/services/kythe/kythe_visitors.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/**
 * Instances of the class [KytheDomainHandler] implement a [RequestHandler]
 * that handles requests in the `kythe` domain.
 */
class KytheDomainHandler extends AbstractRequestHandler {
  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  KytheDomainHandler(AnalysisServer server) : super(server);

  /**
   * Implement the `kythe.getKytheEntries` request.
   */
  Future<Null> getKytheEntries(Request request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    String file = new KytheGetKytheEntriesParams.fromRequest(request).file;
    AnalysisDriver driver = server.getAnalysisDriver(file);
    if (driver == null) {
      server.sendResponse(new Response.getKytheEntriesInvalidFile(request));
    } else {
      //
      // Allow plugins to start computing entries.
      //
      plugin.KytheGetKytheEntriesParams requestParams =
          new plugin.KytheGetKytheEntriesParams(file);
      Map<PluginInfo, Future<plugin.Response>> pluginFutures = server
          .pluginManager
          .broadcastRequest(requestParams, contextRoot: driver.contextRoot);
      //
      // Compute entries generated by server.
      //
      List<KytheGetKytheEntriesResult> allResults =
          <KytheGetKytheEntriesResult>[];
      AnalysisResult result = await server.getAnalysisResult(file);
      CompilationUnit unit = result?.unit;
      if (unit != null && result.exists) {
        List<KytheEntry> entries = <KytheEntry>[];
        // TODO(brianwilkerson) Figure out how to get the list of files.
        List<String> files = <String>[];
        result.unit.accept(new KytheDartVisitor(
            server.resourceProvider,
            entries,
            file,
            new InheritanceManager(result.libraryElement),
            result.content));
        allResults.add(new KytheGetKytheEntriesResult(entries, files));
      }
      //
      // Add the entries produced by plugins to the server-generated entries.
      //
      if (pluginFutures != null) {
        List<plugin.Response> responses = await waitForResponses(pluginFutures,
            requestParameters: requestParams);
        for (plugin.Response response in responses) {
          plugin.KytheGetKytheEntriesResult result =
              new plugin.KytheGetKytheEntriesResult.fromResponse(response);
          allResults.add(
              new KytheGetKytheEntriesResult(result.entries, result.files));
        }
      }
      //
      // Return the result.
      //
      ResultMerger merger = new ResultMerger();
      KytheGetKytheEntriesResult mergedResults =
          merger.mergeKytheEntries(allResults);
      if (mergedResults == null) {
        server.sendResponse(
            new KytheGetKytheEntriesResult(<KytheEntry>[], <String>[])
                .toResponse(request.id));
      } else {
        server.sendResponse(new KytheGetKytheEntriesResult(
                mergedResults.entries, mergedResults.files)
            .toResponse(request.id));
      }
    }
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == KYTHE_REQUEST_GET_KYTHE_ENTRIES) {
        getKytheEntries(request);
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
