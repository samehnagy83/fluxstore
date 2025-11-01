import 'dart:async';

import 'package:flux_interface/flux_interface.dart';
import 'package:inspireui/utils/logs.dart';

import '../offline_handler.dart';

mixin RepositoryLocalMixin on HandlerApiMixin {
  final OfflineHandler _offlineHanlder = OfflineHandler();
  @override
  String get keyCacheLocal;

  @override
  Future<T> callApi<T>(
    Future<T> Function() funcApi, {
    required String key,
    List? keys,
    bool useCache = true,
  }) async {
    try {
      if (_offlineHanlder.isSetKeyCache) {
        _offlineHanlder.setKeyCache(keyCacheLocal);
      }

      return _offlineHanlder.callApi(
        funcApi,
        _offlineHanlder.hashString(key, keys: keys),
        useCache: useCache,
      );
    } catch (e) {
      printError(e);
      throw Exception(e);
    }
  }
}
