import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:inspireui/inspireui.dart';

import '../../common/constants.dart';
import '../../models/entities/store_arguments.dart';
import '../../modules/dynamic_layout/config/app_config.dart';
import '../../screens/chat/chat_arguments.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/chat/wcfm_live_chat_screen.dart';
import 'products/create_product_screen.dart';
import 'products/product_sell_screen.dart';
import 'store/vendor_categories_screen.dart';
import 'store/vendor_list_screen.dart';
import 'store_detail/store_detail_screen.dart';
import 'stores_map/map_screen.dart';

class VendorRoute {
  static dynamic getRoutesWithSettings(RouteSettings settings) {
    final routes = {
      RouteList.storeDetail: (context) {
        final arguments = settings.arguments;
        if (arguments is StoreDetailArgument) {
          return StoreDetailScreen(store: arguments.store);
        }
        return const ErrorPage(message: 'Error argument StoreDetail');
      },
      RouteList.vendorChat: (context) {
        final arguments = settings.arguments;
        if (arguments is ChatArguments) {
          return ChatScreen(
            receiverEmail: arguments.receiverEmail,
            receiverName: arguments.receiverName,
            product: arguments.product,
          );
        }
        return const ErrorPage(message: 'Error argument ChatScreen');
      },
      RouteList.wcfmLiveChatStore: (context) {
        final arguments = settings.arguments;
        if (arguments is ChatArguments) {
          return WcfmLiveChatScreen(
            receiverId: arguments.receiverId,
            receiverEmail: arguments.receiverEmail,
            receiverName: arguments.receiverName,
            product: arguments.product,
          );
        }
        return const ErrorPage(message: 'Error argument ChatScreen');
      },
      RouteList.vendorCategory: (context) {
        final data = settings.arguments;
        if (data is TabBarMenuConfig) {
          return VendorCategoriesScreen(
            categoryLayout: data.jsonData['categoryLayout'],
            enableParallax: data.jsonData['parallax'] ?? false,
            parallaxImageRatio: Tools.formatDouble(
              data.jsonData['parallaxImageRatio'],
            ),
          );
        }
        return const VendorCategoriesScreen();
      },
      RouteList.vendorList: (context) => const VendorListScreen(),
      RouteList.createProduct: (context) => const CreateProductScreen(),
      RouteList.productSell: (context) => ProductSellScreen(),
      RouteList.listChat: (_) => const ChatScreen(),
      RouteList.wcfmLiveChat: (_) => const WcfmLiveChatScreen(),
      RouteList.map: (_) => const MapScreen(),
    };
    if (routes.containsKey(settings.name)) {
      return routes[settings.name!];
    }
    return (context) => const ErrorPage(message: 'Page not found');
  }
}
