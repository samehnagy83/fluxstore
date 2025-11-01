import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/index.dart';
import '../../../models/product_variant_model.dart';
import 'yith_checkbox_item.dart';
import 'yith_input_item.dart';
import 'yith_radio_item.dart';
import 'yith_select_item.dart';
import 'yith_text_item.dart';

class YithAddonsWidget extends StatefulWidget {
  final Product product;
  final bool isProductInfoLoading;
  final Function? onChanged;

  const YithAddonsWidget({
    super.key,
    required this.product,
    this.isProductInfoLoading = false,
    this.onChanged,
  });

  @override
  State<YithAddonsWidget> createState() => _YithAddonsWidgetState();
}

class _YithAddonsWidgetState extends State<YithAddonsWidget> {
  ProductVariantModel get model => context.read<ProductVariantModel>();

  Map<String, Map<String, YithAddonsOption>> get selectedOptions =>
      model.selectedYithOptions;

  double get basePrice =>
      model.productVariation?.valuePrice ?? widget.product.valuePrice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        updateDefaultAddonsOption();
      }
    });
  }

  @override
  void didUpdateWidget(covariant YithAddonsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProductInfoLoading != oldWidget.isProductInfoLoading) {
      updateDefaultAddonsOption();
    }
  }

  void updateDefaultAddonsOption() {
    final addOns = widget.product.addOns ?? [];
    if (!widget.isProductInfoLoading && addOns.isNotEmpty) {
      var options = Map<String, Map<String, YithAddonsOption>>.from(
        selectedOptions,
      );
      //TODO: Load default options
      model.updateValues(selectedYithOptions: options);
    }
  }

  void onSelectProductAddons({
    required String? key,
    required Map<String, YithAddonsOption> value,
  }) {
    if (key == null) {
      return;
    }
    var options =
        Map<String, Map<String, YithAddonsOption>>.from(selectedOptions);
    options[key] = value;
    model.updateValues(selectedYithOptions: options);
  }

  Widget renderYithItem({
    required YithProductAddons item,
    required Map<String, YithAddonsOption> selected,
    String? key,
  }) {
    switch (item.type) {
      case YithAddonsType.radio:
        return YithRadioItem(
          item: item,
          basePrice: basePrice,
          selected: selected,
          onSelectProductAddons: (value) => onSelectProductAddons(
            key: key,
            value: value,
          ),
        );
      case YithAddonsType.checkbox:
        return YithCheckboxItem(
          item: item,
          basePrice: basePrice,
          selected: selected,
          onSelectProductAddons: (value) => onSelectProductAddons(
            key: key,
            value: value,
          ),
        );

      case YithAddonsType.select:
        return YithSelectItem(
          item: item,
          basePrice: basePrice,
          selected: selected,
          onSelectProductAddons: (value) => onSelectProductAddons(
            key: key,
            value: value,
          ),
        );

      case YithAddonsType.input_text:
        return YithInputItem(
          item: item,
          basePrice: basePrice,
          selected: selected,
          onSelectProductAddons: (value) => onSelectProductAddons(
            key: key,
            value: value,
          ),
        );
      case YithAddonsType.text:
      case YithAddonsType.heading:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: YithTextItem(
            item: item,
          ),
        );
      case YithAddonsType.separator:
        return const Divider();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final yithAddOns = widget.product.yithAddOns ?? [];

    if (yithAddOns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        ...yithAddOns.map((addon) {
          final key = addon.title;
          final selected = Map<String, YithAddonsOption>.from(
            key != null ? (selectedOptions[key] ?? {}) : {},
          );

          return renderYithItem(
            item: addon,
            selected: selected,
            key: key,
          );
        }),
      ],
    );
  }
}
