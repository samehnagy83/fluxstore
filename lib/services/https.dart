import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:inspireui/inspireui.dart';
// ignore: depend_on_referenced_packages
import 'package:logger/logger.dart';

import '../common/config.dart';
import 'http_cache_manager.dart';

const isBuilder = false;

/// The default http GET that support Logging
Future<http.Response> httpCache(
  Uri uri, {
  Map<String, String>? headers,
  bool refreshCache = false,
}) async {
  final startTime = DateTime.now();

  // Enable default on FluxBuilder
  if (kAdvanceConfig.httpCache || isBuilder) {
    final key = uri.toString();
    try {
      if (refreshCache) {
        await _removeCache(key);
      }

      var file = await HttpCacheManager().getSingleFile(
        key,
        headers: (headers ?? {})..addAll({'Content-Encoding': 'gzip'}),
      );

      if (await file.exists()) {
        var res = await file.readAsString();
        var fileSize = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);

        printLog('📥 GET CACHE($fileSize mb):$key', startTime);
        return http.Response(res, 200);
      }
      return http.Response('', 404);
    } catch (e) {
      printLog('CACHE ISSUE: ${e.toString()}', startTime, Level.debug);
      unawaited(_removeCache(key));
    }
  }
  return httpGet(uri, headers: headers, refreshCache: refreshCache);
}

Future<void> _removeCache(final String key) async {
  try {
    await HttpCacheManager().removeFile(key);
    printLog('🔴 REMOVE CACHE:$key', null, Level.debug);
  } catch (e) {
    printLog('CLEAR CACHE ISSUE: ${e.toString()}', null, Level.debug);
  }
}
