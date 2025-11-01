import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';

import '../../common/constants.dart';
import '../../common/tools/navigate_tools.dart';
import '../../menu/index.dart';
import '../../models/order/order.dart';
import '../../services/service_config.dart';
import '../dynamic_layout/helper/helper.dart';
import 'widgets/re_order_item_list.dart';
import 'widgets/shopify_re_order_item_list.dart';

mixin ReOderMixin {
  /// Check if current framework is Shopify
  bool get _isShopify => ServerConfig().isShopify;

  /// Get appropriate ReOrder widget based on framework
  Widget _getReOrderWidget(Order order) {
    printLog(
        'ReOderMixin: Getting ReOrder widget for framework: ${_isShopify ? 'Shopify' : 'Other'}');
    printLog('ReOderMixin: Order has ${order.lineItems.length} line items');

    if (_isShopify) {
      return ShopifyReOrderItemList(lineItems: order.lineItems);
    } else {
      return ReOrderItemList(
        lineItems: order.lineItems,
        b2bKingIsB2BOrder: order.b2bKingIsB2BOrder,
      );
    }
  }

  void reOrder(BuildContext context, Order order) async {
    var result;
    final productBooking = order.lineItems
        .firstWhereOrNull((item) => item.product?.type == 'appointment');

    if (productBooking != null) {
      NavigateTools.navigateToProductDetail(
        context,
        isFromSearchScreen: false,
        product: productBooking.product,
      );
      return;
    }

    if (Layout.isDisplayDesktop(context)) {
      result = await showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              width: 500,
              height: MediaQuery.sizeOf(context).height * 0.8,
              child: _getReOrderWidget(order),
            ),
          );
        },
      );
    } else {
      result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 1,
          builder: (BuildContext context, ScrollController scrollController) {
            return _getReOrderWidget(order);
          },
        ),
      );
    }

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).yourOrderHasBeenAdded),
          duration: const Duration(seconds: 3),
        ),
      );
      await MainTabControlDelegate.getInstance().changeTab(RouteList.cart);
    }
  }
}
