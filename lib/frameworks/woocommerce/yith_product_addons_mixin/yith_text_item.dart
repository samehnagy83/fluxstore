import 'package:flutter/material.dart';

import '../../../models/entities/yith_product_addons.dart';

class YithTextItem extends StatelessWidget {
  const YithTextItem({super.key, required this.item});
  final YithProductAddons item;

  @override
  Widget build(BuildContext context) {
    if (item.type == YithAddonsType.text) {
      return Text(
        item.title ?? '',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
      );
    } else {
      return Text(
        item.title ?? '',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
      );
    }
  }
}
