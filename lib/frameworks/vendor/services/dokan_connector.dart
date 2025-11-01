import '../../../services/offline_mode/network_aware/http_aware_mixin.dart';
import '../../../services/offline_mode/network_aware/network_aware_api_mixin.dart';
import 'dokan_api.dart';

class DokanConnector
    with NetworkAwareApiMixin, HttpAwareMixin
    implements DokanAPI {
  final DokanAPI _dokanApi;

  DokanConnector(String domain) : _dokanApi = DokanAPI(url: domain);

  @override
  String get keyCacheLocal => 'dokan-connector';

  @override
  String? get url => _dokanApi.url;

  @override
  set url(String? url) {
    _dokanApi.url = url;
  }

  @override
  Future getAsync(String endPoint) => callApi(
        () async => await _dokanApi.getAsync(endPoint),
        key: 'get',
        keys: [endPoint],
      );
}
