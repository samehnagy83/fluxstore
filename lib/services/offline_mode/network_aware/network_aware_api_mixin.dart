import 'package:flux_interface/flux_interface.dart';

import '../mixins/repositoty_local_mixin.dart';

class _ApiAction with HandlerApiMixin, RepositoryLocalMixin {
  @override
  String get keyCacheLocal => keyCache;

  final String keyCache;

  _ApiAction(this.keyCache);
}

mixin NetworkAwareApiMixin implements HandlerApiMixin {
  late final _ApiAction _apiAction = _ApiAction(keyCacheLocal);
  @override
  String get keyCacheLocal;

  @override
  Future<T> callApi<T>(
    Future<T> Function() funcApi, {
    required String key,
    List? keys,
    bool useCache = true,
  }) =>
      _apiAction.callApi(funcApi, key: key, keys: keys);
}
