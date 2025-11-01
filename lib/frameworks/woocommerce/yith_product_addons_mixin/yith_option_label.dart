import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/tools/price_tools.dart';
import '../../../common/tools/yith_addons_tools.dart';
import '../../../models/cart/cart_base.dart';
import '../../../models/entities/index.dart';

class YithOptionLabel extends StatelessWidget {
  const YithOptionLabel({
    super.key,
    this.option,
    required this.basePrice,
  });
  final YithAddonsOption? option;
  final double basePrice;

  @override
  Widget build(BuildContext context) {
    if (option == null) {
      return Text(
        option?.label ?? '',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
      );
    }

    var model = context.read<CartModel>();
    var hasSalePrice = option?.salePrice?.isNotEmpty ?? false;
    final rates = model.currencyRates;
    final currency = model.currencyCode;
    var salePrice = YithAddonsTools.getYithOptionPrice(basePrice, option!);
    var sign = salePrice < 0 ? '-' : '+';
    var regularPrice =
        YithAddonsTools.getYithOptionPrice(basePrice, option!, isOnSale: false);

    return RichText(
      text: TextSpan(
        text: option?.label ?? '',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
        children: <TextSpan>[
          if (hasSalePrice) ...[
            TextSpan(
              text: ' ($sign',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 11),
            ),
            TextSpan(
              text: PriceTools.getCurrencyFormatted(
                regularPrice,
                rates,
                currency: currency,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey),
            ),
            TextSpan(
              text: ' ${PriceTools.getCurrencyFormatted(
                salePrice,
                rates,
                currency: currency,
              )}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 11),
            ),
            TextSpan(
              text: ')',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 11),
            ),
          ],
          if (!hasSalePrice)
            TextSpan(
              text:
                  ' ${YithAddonsTools.getPriceValueByOption(model, basePrice, option)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 11),
            ),
        ],
      ),
    );
  }
}
