import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/tools.dart';
import '../../../models/entities/listing_type_name.dart';
import '../../../models/index.dart' show CartModel, Product;
import '../../../services/service_config.dart';
import '../../../services/services.dart';
import '../../../widgets/card/phone_item.dart';
import '../../../widgets/card/tag_item.dart';
import '../../../widgets/common/star_rating.dart';
import '../../../widgets/product/action_button_mixin.dart';
import '../../../widgets/product/index.dart';
import '../../../widgets/product/widgets/category_name.dart';
import '../config/product_config.dart';
import '../helper/helper.dart';

class PinterestCard extends StatelessWidget with ActionButtonMixin {
  final Product item;
  final width;
  final ProductConfig config;

  const PinterestCard({
    required this.item,
    this.width,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = Provider.of<CartModel>(context).currencyCode;
    final currencyRates = Provider.of<CartModel>(context).currencyRates;
    final isTablet = Helper.isTablet(MediaQuery.of(context));

    var titleFontSize = isTablet ? 24.0 : 14.0;
    var starSize = isTablet ? 20.0 : 10.0;
    var showCart =
        config.showCartIcon && Services().widget.enableShoppingCart(item);

    var isSale = (item.onSale ?? false) &&
        PriceTools.getPriceProductValue(item, onSale: true) !=
            PriceTools.getPriceProductValue(item, onSale: false);

    var priceProduct = PriceTools.getPriceProduct(item, currencyRates, currency,
        onSale: isSale)!;

    return GestureDetector(
      onTap: () => onTapProduct(context, product: item, config: config),
      child: Container(
        color: Theme.of(context).cardColor,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ImageResize(
                  url: item.imageFeature,
                  width: width,
                  size: kSize.medium,
                  isResize: true,
                  fit: ImageTools.boxFit(config.imageBoxfit),
                ),
                if (!config.showOnlyImage)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      ListingTypeName(
                        product: item,
                        show: config.showListingType,
                      ),
                      CategoryName(
                        product: item,
                        show: config.showProductCardCategory,
                      ),
                      ProductTitle(
                        product: item,
                        hide: config.hideTitle,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      StoreName(product: item, hide: config.hideStore),
                      PhoneItem(
                        item: item,
                        show: config.showPhoneNumber,
                      ),
                      TagItem(
                        item: item,
                        hide: config.hideAddress,
                      ),
                      if (!config.hidePrice) ...[
                        const SizedBox(height: 6),
                        Text(
                          priceProduct,
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                          ),
                        )
                      ],
                      if (config.showStockStatus) ...[
                        StockStatus(
                          product: item,
                          config: config,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          if (config.enableRating)
                            Expanded(
                              child: SmoothStarRating(
                                allowHalfRating: true,
                                starCount: 5,
                                label: Text(
                                  '${item.ratingCount}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                rating: item.averageRating,
                                size: starSize,
                                color: theme.primaryColor,
                                borderColor: theme.primaryColor,
                                spacing: 0.0,
                              ),
                            ),
                          if (showCart &&
                              !item.isEmptyProduct() &&
                              !ServerConfig().isListingType) ...[
                            Align(
                              alignment: context.isRtl
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: CartIcon(product: item, config: config),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ],
                      ),
                    ],
                  )
              ],
            ),
            if (config.showHeart && !item.isEmptyProduct())
              Positioned(
                top: 0,
                right: 0,
                child: HeartButton(product: item, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
