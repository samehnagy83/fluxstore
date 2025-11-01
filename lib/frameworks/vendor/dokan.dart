import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../models/index.dart' show Product;
import '../../modules/dynamic_layout/config/geo_search_config.dart';
import '../../modules/dynamic_layout/geo_search/geo_search.dart';

import '../woocommerce/index.dart';
import 'vendor_mixin.dart';

class DokanWidget extends WooWidget with VendorMixin {
  @override
  Product updateProductObject(Product product, Map? json) {
    if (json!['store'] != null && json['store']['id'] != null) {
      product.store = Store.fromDokanJson(json['store']);
    }
    return product;
  }

  @override
  Widget renderGeoSearch(Map<String, dynamic> config) {
    return GeoSearch(
      geoSearchConfig: GeoSearchConfig.fromJson(config),
    );
  }
}
