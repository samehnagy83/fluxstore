import 'dart:io';

import 'package:http/http.dart' as http;

import '../offline_mode/network_aware/http_aware_mixin.dart';
import '../offline_mode/network_aware/network_aware_api_mixin.dart';
import 'wordpress_api.dart';

class WordpressConnector
    with NetworkAwareApiMixin, HttpAwareMixin
    implements WordpressApi {
  WordpressConnector(this._api);

  final WordpressApi _api;

  @override
  String get keyCacheLocal => 'wordpress-connector';

  @override
  Future getAsync(String endPoint) async => callApi(
        () async => await _api.getAsync(endPoint),
        key: 'get',
        keys: [endPoint],
      );

  @override
  Future<http.StreamedResponse> getStream(String endPoint) {
    return callApi(() async => await _api.getStream(endPoint),
        key: 'stream', keys: [endPoint]);
  }

  @override
  Future postAsync(String endPoint, Map? data, {String? token}) {
    return callApi(
      () async => await _api.postAsync(endPoint, data, token: token),
      key: 'post',
      keys: [
        endPoint,
        data,
        token,
      ],
    );
  }

  @override
  Future putAsync(String endPoint, Map data) {
    return callApi(
      () async => await _api.putAsync(endPoint, data),
      key: 'put',
      keys: [
        endPoint,
        data,
      ],
    );
  }

  @override
  Future uploadBlogImage(File imageFile, String token) {
    return _api.uploadBlogImage(imageFile, token);
  }

  @override
  String get url => _api.url;

  @override
  bool get isRoot => _api.isRoot;
}
