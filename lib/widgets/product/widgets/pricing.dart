import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../common/tools.dart';
import '../../../models/index.dart' show AppModel, Product;
import '../../../services/index.dart';

class ProductPricing extends StatelessWidget {
  final Product product;
  final bool hide;
  final bool showOnlyPrice;
  final TextStyle? priceTextStyle;

  const ProductPricing({
    super.key,
    required this.product,
    required this.hide,
    this.showOnlyPrice = false,
    this.priceTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (hide ||
        product.isEmptyProduct() ||
        Services().widget.hideProductPrice(context, product)) {
      return const SizedBox();
    }

    final currency = Provider.of<AppModel>(context, listen: false).currencyCode;
    final currencyRate = Provider.of<AppModel>(context).currencyRate;

    /// Calculate the Sale price
    var isSale = (product.onSale ?? false) &&
        PriceTools.getPriceProductValue(product, onSale: true) !=
            PriceTools.getPriceProductValue(product, onSale: false);

    if (product.isVariableProduct) {
      isSale = product.onSale ?? false;
    }

    var price = PriceTools.getPriceProduct(
      product,
      currencyRate,
      currency,
      onSale: true,
    )!;

    if (product.isVariableProduct) {
      final minPrice = double.tryParse('${product.minPrice}') ?? 0.0;
      final maxPrice = double.tryParse('${product.maxPrice}') ?? 0.0;

      if (maxPrice > minPrice && minPrice > 0.0) {
        price = '${PriceTools.getCurrencyFormatted(
          minPrice,
          currencyRate,
          currency: currency,
        )!} - ${PriceTools.getCurrencyFormatted(
          maxPrice,
          currencyRate,
          currency: currency,
        )!}';
      }
    } else if (product.isGroupedProduct) {
      price = '${S.of(context).from} ${PriceTools.getPriceProduct(
        product,
        currencyRate,
        currency,
        onSale: true,
      )}';
    } else if (product.isListing) {
      // Listing have a different logic
      final minPrice = double.tryParse('${product.minPrice}') ?? 0.0;
      final maxPrice = double.tryParse('${product.maxPrice}') ?? 0.0;
      final regularPrice = double.tryParse('${product.regularPrice}') ?? 0.0;
      final weekdayPrice = double.tryParse('${product.price}') ?? 0.0;

      String formatPrice(double value) => PriceTools.getCurrencyFormatted(
            value,
            currencyRate,
            currency: currency,
          )!;

      // Handle different listing themes
      if (ServerConfig().isListeoType || ServerConfig().isListProType) {
        // Priority 1: Show min-max price range if both exist
        if (minPrice > 0 && maxPrice > 0) {
          price = '${formatPrice(minPrice)} - ${formatPrice(maxPrice)}';
        }
        // Priority 2: Show single price from min/max if either exists
        else if (minPrice > 0) {
          price = S.of(context).startsFrom(formatPrice(minPrice));
        } else if (maxPrice > 0) {
          price = S.of(context).upTo(formatPrice(maxPrice));
        }
        // Priority 3: Show regular-weekday price range if both exist
        else if (regularPrice > 0 && weekdayPrice > 0) {
          price = '${formatPrice(regularPrice)} - ${formatPrice(weekdayPrice)}';
        }
        // Priority 4: Show single price from regular/weekday if either exists
        else if (regularPrice > 0) {
          price = S.of(context).startsFrom(formatPrice(regularPrice));
        } else if (weekdayPrice > 0) {
          price = S.of(context).upTo(formatPrice(weekdayPrice));
        }
        // Priority 5: Empty price if no valid price exists
        else {
          price = '';
        }
      } else {
        // For mylisting theme, show single price without prefix
        price = regularPrice > 0 ? formatPrice(regularPrice) : '';
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: <Widget>[
        Text(
          price,
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
              )
              .apply(fontSizeFactor: 0.8)
              .merge(priceTextStyle),
        ),

        /// Not show regular price for variant product (product.regularPrice = "").
        if (isSale && product.type != 'variable' && showOnlyPrice == false) ...[
          const SizedBox(width: 5),
          Text(
            product.type == 'grouped'
                ? ''
                : PriceTools.getPriceProduct(product, currencyRate, currency,
                    onSale: false)!,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(
                  fontWeight: FontWeight.w300,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValueOpacity(0.6),
                  decoration: TextDecoration.lineThrough,
                  overflow: TextOverflow.ellipsis,
                )
                .apply(fontSizeFactor: 0.8)
                .merge(
                  priceTextStyle?.copyWith(
                      color: priceTextStyle?.color?.withValueOpacity(0.6),
                      fontSize: priceTextStyle?.fontSize != null
                          ? priceTextStyle!.fontSize! - 2
                          : null),
                ),
          ),
        ],
      ],
    );
  }
}
