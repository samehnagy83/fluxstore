import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:inspireui/extensions.dart';
import 'package:provider/provider.dart';

import '../../common/tools/price_tools.dart';
import '../../models/app_model.dart';
import '../../models/entities/badge_management/yith_badge.dart';
import '../../models/entities/product.dart';
import 'views/advanced/advanced_1.dart';
import 'views/advanced/advanced_10.dart';
import 'views/advanced/advanced_2.dart';
import 'views/advanced/advanced_3.dart';
import 'views/advanced/advanced_4.dart';
import 'views/advanced/advanced_5.dart';
import 'views/advanced/advanced_6.dart';
import 'views/advanced/advanced_7.dart';
import 'views/advanced/advanced_8.dart';
import 'views/advanced/advanced_9.dart';
import 'views/css/css_1.dart';
import 'views/css/css_2.dart';
import 'views/css/css_3.dart';
import 'views/css/css_4.dart';
import 'views/css/css_5.dart';
import 'views/css/css_6.dart';
import 'views/css/css_7.dart';
import 'views/css/css_8.dart';
import 'views/helper.dart';

mixin BadgeManagementMixin {
  Widget _renderCSSContent(YITHBadge badge) {
    Widget contentWidget = const SizedBox();
    var textContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HtmlWidget(
          badge.text ?? '',
          textStyle: TextStyle(
            color: badge.textColor,
          ),
        )
      ],
    );
    switch (badge.css) {
      case '1.svg':
        contentWidget = YITHBadgeCSS1(
          badge: badge,
          child: textContent,
        );
        break;
      case '2.svg':
        contentWidget = YITHBadgeCSS2(
          badge: badge,
          child: textContent,
        );
        break;
      case '3.svg':
        contentWidget = YITHBadgeCSS3(
          badge: badge,
          child: textContent,
        );
        break;
      case '4.svg':
        contentWidget = YITHBadgeCSS4(
          badge: badge,
          child: textContent,
        );
        break;
      case '5.svg':
        contentWidget = YITHBadgeCSS5(
          badge: badge,
          child: textContent,
        );
        break;
      case '6.svg':
        contentWidget = YITHBadgeCSS6(
          badge: badge,
          child: textContent,
        );
        break;
      case '7.svg':
        contentWidget = YITHBadgeCSS7(
          badge: badge,
          child: textContent,
        );
        break;
      case '8.svg':
        contentWidget = YITHBadgeCSS8(
          badge: badge,
          child: textContent,
        );
        break;
    }
    return contentWidget;
  }

  Widget _renderAdvancedContent(
      BuildContext context, Product product, YITHBadge badge) {
    final currency = Provider.of<AppModel>(context, listen: false).currencyCode;

    Widget contentWidget = const SizedBox();

    double? regularPrice = 0.0;
    var salePercent = 0;
    var saleAmount = 0.0;
    if (product.regularPrice != null &&
        product.regularPrice!.isNotEmpty &&
        product.regularPrice != '0.0') {
      regularPrice = (double.tryParse(product.regularPrice.toString()));
    }

    /// Calculate the Sale price
    var isSale = (product.onSale ?? false) &&
        PriceTools.getPriceProductValue(product, onSale: true) !=
            PriceTools.getPriceProductValue(product, onSale: false);
    if (isSale && regularPrice != 0) {
      saleAmount = (double.parse(product.salePrice!) - regularPrice!);
      salePercent = saleAmount * 100 ~/ regularPrice;
    }
    var saleAmountStr = PriceTools.getCurrencyFormatted('$saleAmount', null,
            currency: currency) ??
        '';

    if (salePercent == 0) {
      return contentWidget;
    }
    switch (badge.advanced) {
      case '1.svg':
        contentWidget = YITHBadgeAdvanced1(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
      case '2.svg':
        contentWidget = YITHBadgeAdvanced2(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
      case '3.svg':
        contentWidget = YITHBadgeAdvanced3(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
      case '4.svg':
        contentWidget = YITHBadgeAdvanced4(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
      case '5.svg':
        contentWidget = YITHBadgeAdvanced5(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
      case '6.svg':
        contentWidget = YITHBadgeAdvanced6(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
      case '7.svg':
        contentWidget = YITHBadgeAdvanced7(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
      case '8.svg':
        contentWidget = YITHBadgeAdvanced8(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
      case '9.svg':
        contentWidget = YITHBadgeAdvanced9(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
      case '10.svg':
        contentWidget = YITHBadgeAdvanced10(
            badge: badge, salePercent: salePercent, saleAmount: saleAmountStr);
        break;
    }
    return contentWidget;
  }

  Widget _renderProductBadge(
    BuildContext context,
    Product product,
    YITHBadge? badge, {
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    if (badge != null) {
      Widget contentWidget = const SizedBox();
      if (badge.type == YITHBadgeType.text) {
        contentWidget = Container(
          width: badge.size?.width,
          height: badge.size?.height,
          decoration: BoxDecoration(
              color:
                  badge.backgroundColor?.withValueOpacity(badge.opacity ?? 1),
              borderRadius: badge.borderRadius),
          padding: badge.padding,
          margin: badge.margin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HtmlWidget(
                badge.text ?? '',
                textStyle: TextStyle(
                  color: badge.textColor,
                ),
              ),
            ],
          ),
        );
      } else if (badge.type == YITHBadgeType.image &&
          (badge.imageUrl?.isNotEmpty ?? false)) {
        contentWidget = FluxImage(
          imageUrl: badge.imageUrl!,
          fit: BoxFit.cover,
        );
      } else if (badge.type == YITHBadgeType.css &&
          (badge.css?.isNotEmpty ?? false)) {
        contentWidget = _renderCSSContent(badge);
      } else if (badge.type == YITHBadgeType.advanced &&
          (badge.advanced?.isNotEmpty ?? false)) {
        contentWidget = _renderAdvancedContent(context, product, badge);
      }

      return Positioned(
        top: 0,
        left: 0,
        bottom: 0,
        right: 0,
        child: Align(
          alignment: YITHBadgeHelper.getAlignmentByBadge(badge) ??
              AlignmentDirectional.centerEnd,
          child: Opacity(
            opacity: badge.opacity ?? 1.0,
            child: Padding(
              padding: padding,
              child: contentWidget,
            ),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  List<Widget> renderProductBadges(
    BuildContext context,
    Product product, {
    bool isDetail = false,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    if (product.hideBadgeOnDetail == true && isDetail) return [];

    return product.badges
            ?.map((badge) =>
                _renderProductBadge(context, product, badge, padding: padding))
            .toList() ??
        [];
  }
}
