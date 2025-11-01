import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/config.dart';
import '../../services/index.dart';
import '../../widgets/common/webview.dart';
import '../base_screen.dart';

class PaymentWebview extends StatefulWidget {
  final String? url;
  final Function? onFinish;
  final Function? onClose;
  final String? token;
  final String? orderNumber;

  const PaymentWebview({
    this.onFinish,
    this.onClose,
    this.url,
    this.token,
    this.orderNumber,
  });

  @override
  State<StatefulWidget> createState() {
    return PaymentWebviewState();
  }
}

class PaymentWebviewState extends BaseScreen<PaymentWebview> {
  int selectedIndex = 1;
  String? orderId;
  var isSuccess = false;

  void handleUrlChanged(String url) {
    // Check if success to avoid calling pop method multiple times
    if (isSuccess) {
      return;
    }

    // WooCommerce
    if (url.contains('/order-received/')) {
      var uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('order_id')) {
        // https://domain.com/order-received/thank-you/?order_id=39022
        orderId ??= uri.queryParameters['order_id']?.toString();
        isSuccess = true;
      } else {
        // https://domain.com/checkout/order-received/38170
        final items = url.split('/order-received/');
        if (items.length > 1) {
          orderId ??= items[1].split('/')[0];
          isSuccess = true;
        }
      }
    }

    if (isSuccess == false && url.contains('checkout/success')) {
      orderId ??= '0';
      isSuccess = true;
    }

    if (isSuccess == false && url.contains('step/store-checkout-thank-you')) {
      var uri = Uri.parse(url);
      // https://domain.com/step/store-checkout-thank-you-03/?wcf-key=wc_order_vBPJb5Yi7xfgJ&wcf-order=4483

      if (uri.queryParameters.containsKey('wcf-order')) {
        orderId ??= uri.queryParameters['wcf-order']?.toString();
        isSuccess = true;
      } else {
        orderId ??= '0';
        isSuccess = true;
      }
    }

    if (isSuccess == false && url.contains('thank-you')) {
      orderId ??= '0';
      isSuccess = true;
    }

    // shopify url final checkout
    if (isSuccess == false && url.contains('thank_you')) {
      orderId ??= '0';
      isSuccess = true;
    }

    // BigCommerce.
    if (isSuccess == false && url.contains('/checkout/order-confirmation')) {
      orderId ??= '0';
      isSuccess = true;
    }

    // Prestashop
    if (isSuccess == false && url.contains('/order-confirmation')) {
      var uri = Uri.parse(url);
      orderId ??= (uri.queryParameters['id_order'] ?? 0).toString();
      isSuccess = true;
    }

    // Finally, custom slug
    if (isSuccess == false &&
        kPaymentConfig.checkoutSuccessPageSlug.any(url.contains)) {
      orderId ??= '0';
      isSuccess = true;
    }

    /// Finally
    if (orderId != null && isSuccess) {
      widget.onFinish?.call(orderId);
      if (kPaymentConfig.showNativeCheckoutSuccessScreenForWebview) {
        Navigator.of(context).pop();
      }
    }

    // Not sure about this case, maybe related to file lib/modules_ext/membership_ultimate/views/signup_screen.dart
    if (url.contains('/member-login/')) {
      orderId = '0';
      widget.onFinish?.call(orderId);
      Navigator.of(context).pop();
    }

    // opencart: exit webview when user press `continue` button after showing 'checkout/success' page. For example https://opencart-demo.mstore.io/index.php?route=checkout/success
    if (url.contains('common/home')) {
      Navigator.of(context).pop();
    }
  }

  void _checkOutOnePage(String url, Map headers) {
    WidgetsBinding.instance.addPostFrameCallback((t) async {
      await Services().widget.onePageCheckoutForWebPWA(
            context,
            url: url,
            headers: Map<String, String>.from(headers),
            orderNumber: widget.orderNumber,
          );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    var checkoutMap = <dynamic, dynamic>{
      'url': '',
      'headers': <String, String>{}
    };

    if (widget.url != null) {
      checkoutMap['url'] = widget.url;
    } else {
      final paymentInfo = Services().widget.getPaymentUrl(context)!;
      checkoutMap['url'] = paymentInfo['url'];
      if (paymentInfo['headers'] != null) {
        checkoutMap['headers'] =
            Map<String, String>.from(paymentInfo['headers']);
      }
    }

    if (widget.token != null && ServerConfig().isShopify) {
      checkoutMap['headers']['X-Shopify-Customer-Access-Token'] = widget.token;
    }

    if (kIsWeb) {
      _checkOutOnePage(
        checkoutMap['url'] ?? '',
        checkoutMap['headers'],
      );
      return const SizedBox();
    }

    return WebView(
      checkoutMap['url'] ?? '',
      headers: checkoutMap['headers'],
      onPageFinished: handleUrlChanged,
      onClosed: () {
        widget.onFinish?.call(orderId);
        widget.onClose?.call();
      },
    );
  }
}
