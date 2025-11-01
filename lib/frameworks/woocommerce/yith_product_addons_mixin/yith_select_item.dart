import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../models/entities/index.dart';
import 'yith_base_item.dart';
import 'yith_option_label.dart';

typedef MenuEntry = DropdownMenuEntry<YithAddonsOption>;

class YithSelectItem extends StatelessWidget {
  const YithSelectItem(
      {super.key,
      required this.item,
      required this.basePrice,
      required this.selected,
      this.onSelectProductAddons});
  final YithProductAddons item;
  final double basePrice;
  final Map<String, YithAddonsOption> selected;
  final void Function(Map<String, YithAddonsOption>)? onSelectProductAddons;

  @override
  Widget build(BuildContext context) {
    final selectedValue = Map<String, YithAddonsOption>.from(selected);
    return SizedBox(
      width: double.infinity,
      child: YithBaseItem(
        item: item,
        child: DropdownButtonFormField<YithAddonsOption>(
          decoration: InputDecoration(
            isDense: true, // Reduces vertical space
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          initialValue: selectedValue.values.firstOrNull,
          isExpanded: true,
          onChanged: (YithAddonsOption? value) {
            if (value == null) return;
            selectedValue.clear();
            selectedValue[value.label ?? ''] = value;
            onSelectProductAddons?.call(selectedValue);
          },
          items: (item.options ?? []).map((YithAddonsOption option) {
            return DropdownMenuItem<YithAddonsOption>(
              value: option,
              child: Container(
                height: 60, // Change this to control item height
                alignment: Alignment.centerLeft,
                child: YithOptionLabel(
                  option: option,
                  basePrice: basePrice,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
