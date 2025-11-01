import '../../../services/offline_mode/network_aware/http_aware_mixin.dart';
import '../../../services/offline_mode/network_aware/network_aware_api_mixin.dart';
import 'wcfm_api.dart';

class WCFMConnector
    with NetworkAwareApiMixin, HttpAwareMixin
    implements WCFMAPI {
  final WCFMAPI _wcfmApi;

  WCFMConnector(String domain) : _wcfmApi = WCFMAPI(url: domain);

  @override
  String get keyCacheLocal => 'wcfm-connector';

  @override
  String? get url => _wcfmApi.url;

  @override
  set url(String? url) {
    _wcfmApi.url = url;
  }

  @override
  Future getAsync(String endPoint) => callApi(
        () async => await _wcfmApi.getAsync(endPoint),
        key: 'get',
        keys: [endPoint],
      );
}
