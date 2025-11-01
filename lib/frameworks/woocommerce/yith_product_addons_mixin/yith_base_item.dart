import 'package:flutter/material.dart';

import '../../../models/entities/yith_product_addons.dart';

class YithBaseItem extends StatelessWidget {
  const YithBaseItem({super.key, required this.item, required this.child});
  final YithProductAddons item;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.title?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Text(
                item.title!,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          if (item.description?.isNotEmpty == true)
            Text(
              item.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
            ),
          const SizedBox(height: 8),
          child
        ],
      ),
    );
  }
}
