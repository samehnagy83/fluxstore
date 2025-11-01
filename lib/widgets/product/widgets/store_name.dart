import 'package:flutter/material.dart';

import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import '../../../models/entities/product.dart';

class StoreName extends StatelessWidget {
  final Product product;
  final bool hide;

  const StoreName({
    super.key,
    required this.product,
    required this.hide,
  });

  @override
  Widget build(BuildContext context) {
    final storeName = product.store?.name;

    if (hide == true || storeName.isEmptyOrNull) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        '${S.of(context).soldBy} $storeName',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
