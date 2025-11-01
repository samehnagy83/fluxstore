import 'package:http/http.dart' as http;
import 'package:inspireui/inspireui.dart' as inspireui;

import '../../../../services/https.dart' as httpmethod;
import 'network_aware_api_mixin.dart';

mixin HttpAwareMixin on NetworkAwareApiMixin {
  @override
  String get keyCacheLocal;

  Future<http.Response> httpGet(
    Uri uri, {
    Map<String, String>? headers,
    bool enableDio = false,
    bool refreshCache = false,
    bool useCache = true,
  }) =>
      callApi(
        () async => await inspireui.httpGet(uri,
            headers: headers, enableDio: enableDio, refreshCache: refreshCache),
        key: 'httpGet',
        keys: [
          uri.toString(),
          headers,
        ],
        useCache: useCache,
      );

  Future<http.Response> httpPost(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool useCache = true,
    bool enableDio = false,
  }) =>
      callApi(
        () async => await inspireui.httpPost(uri,
            headers: headers, body: body, enableDio: enableDio),
        key: 'httpPost',
        keys: [
          uri.toString(),
          headers,
          body,
        ],
        useCache: useCache,
      );

  Future<http.Response> httpCache(Uri uri,
          {Map<String, String>? headers, bool refreshCache = false}) =>
      callApi(
        () async => await httpmethod.httpCache(uri,
            headers: headers, refreshCache: refreshCache),
        key: 'httpCache',
        keys: [
          uri.toString(),
          headers,
        ],
      );

  Future<http.Response> httpDelete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool enableDio = false,
    bool useCache = true,
  }) =>
      callApi(
        () async => await inspireui.httpDelete(uri,
            headers: headers, body: body, enableDio: enableDio),
        key: 'httpDelete',
        keys: [
          uri.toString(),
          headers,
          body,
        ],
        useCache: useCache,
      );

  Future<http.Response> httpPatch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool enableDio = false,
    bool useCache = true,
  }) =>
      callApi(
        () async => await inspireui.httpPatch(uri,
            headers: headers, body: body, enableDio: enableDio),
        key: 'httpPatch',
        keys: [
          uri.toString(),
          headers,
          body,
        ],
        useCache: useCache,
      );

  Future<http.Response> httpPut(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool enableDio = false,
    bool useCache = true,
  }) =>
      callApi(
        () async => await inspireui.httpPut(uri,
            headers: headers, body: body, enableDio: enableDio),
        key: 'httpPut',
        keys: [
          uri.toString(),
          headers,
          body,
        ],
        useCache: useCache,
      );
}
