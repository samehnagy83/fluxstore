import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../models/index.dart' show Product;
import '../../modules/dynamic_layout/config/geo_search_config.dart';
import '../../modules/dynamic_layout/geo_search/geo_search.dart';
import '../../modules/store_open_option/store_open_option.dart';
import '../woocommerce/index.dart';
import 'vendor_mixin.dart';

class WCFMWidget extends WooWidget with VendorMixin {
  @override
  Product updateProductObject(Product product, Map? json) {
    if (json!['store'] != null && json['store']['vendor_id'] != null) {
      product.store = Store.fromWCFMJson(json['store']);
    }
    return product;
  }

  @override
  Widget renderGeoSearch(Map<String, dynamic> config) {
    return GeoSearch(
      geoSearchConfig: GeoSearchConfig.fromJson(config),
    );
  }

  @override
  Widget renderVacationVendor(String userId, String cookie,
      {bool isFromMV = true}) {
    return StoreOpenOptionIndex(
      isFromMV: isFromMV,
      cookie: cookie,
      userId: userId,
      key: const Key('renderOpenCloseVendor'),
    );
  }
}
