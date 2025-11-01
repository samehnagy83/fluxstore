import 'package:flutter/material.dart';

import '../../../models/entities/index.dart';
import 'yith_addons_widget.dart';

export 'yith_addons_widget.dart';

mixin YithProductAddonsMixin {
  List<Widget> getYithProductAddonsWidget({
    required BuildContext context,
    String? lang,
    required Product product,
    required bool isProductInfoLoading,
    Function? onChanged,
  }) {
    if (product.yithAddOns?.isNotEmpty ?? false) {
      return [
        YithAddonsWidget(
          product: product,
          isProductInfoLoading: isProductInfoLoading,
        )
      ];
    }
    return const [SizedBox()];
  }
}
