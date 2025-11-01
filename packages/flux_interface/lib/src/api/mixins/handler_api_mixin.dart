import 'package:fstore/common/constants.dart';

mixin HandlerApiMixin {
  String get keyCacheLocal;
  Future<T> callApi<T>(
    Future<T> Function() funcApi, {
    required String key,
    List? keys,
    bool useCache = true,
  }) async {
    try {
      return await funcApi();
    } catch (e) {
      printError(e);
      throw Exception(e);
    }
  }
}
