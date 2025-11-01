import 'package:http/http.dart';

import '../../../services/offline_mode/network_aware/http_aware_mixin.dart';
import '../../../services/offline_mode/network_aware/network_aware_api_mixin.dart';
import 'woocommerce_api.dart';

class WooComerceConnector
    with NetworkAwareApiMixin, HttpAwareMixin
    implements WooCommerceAPI {
  final WooCommerceAPI _wcApi;

  WooComerceConnector(this._wcApi);

  @override
  String get keyCacheLocal => 'woo-connector';

  @override
  Future<dynamic> getAsync(
    String endPoint, {
    int version = 2,
    bool enableDio = false,
    bool refreshCache = false,
  }) async =>
      callApi(
        () async => await _wcApi.getAsync(
          endPoint,
          version: version,
          enableDio: enableDio,
          refreshCache: refreshCache,
        ),
        key: 'get',
        keys: [endPoint, version],
      );

  @override
  Future<StreamedResponse> getStream(String endPoint) async => callApi(
        () async => await _wcApi.getStream(endPoint),
        key: 'stream',
        keys: [endPoint],
      );

  @override
  Future postAsync(String endPoint, Map data, {int version = 2}) async =>
      callApi(
        () async => await _wcApi.postAsync(endPoint, data, version: version),
        key: 'post',
        keys: [
          endPoint,
          version,
          data,
        ],
      );

  @override
  Future putAsync(String endPoint, Map data, {int version = 3}) async =>
      callApi(
        () async => await _wcApi.putAsync(endPoint, data, version: version),
        key: 'put',
        keys: [
          endPoint,
          version,
          data,
        ],
      );

  @override
  String getOAuthURLExternal(String url) => _wcApi.getOAuthURLExternal(url);

  @override
  String? get consumerKey => _wcApi.consumerKey;

  @override
  String? get consumerSecret => _wcApi.consumerSecret;

  @override
  bool? get isHttps => _wcApi.isHttps;

  @override
  String? get url => _wcApi.url;

  @override
  set consumerKey(String? consumerKey) {
    _wcApi.consumerKey = consumerKey;
  }

  @override
  set consumerSecret(String? consumerSecret) {
    _wcApi.consumerSecret = consumerSecret;
  }

  @override
  set isHttps(bool? isHttps) {
    _wcApi.isHttps = isHttps;
  }

  @override
  set url(String? url) {
    _wcApi.url = url;
  }
}
