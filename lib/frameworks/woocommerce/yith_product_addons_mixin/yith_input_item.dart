import 'package:flutter/material.dart';

import '../../../models/entities/index.dart';
import 'yith_base_item.dart';
import 'yith_option_label.dart';

class YithInputItem extends StatelessWidget {
  const YithInputItem(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(item.options?.length ?? 0, (index) {
              final option = item.options?[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YithOptionLabel(
                    option: option,
                    basePrice: basePrice,
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    onChanged: (String? value) {
                      if (value == null) return;
                      if (value.isEmpty) {
                        selectedValue.remove(option?.label);
                      } else {
                        selectedValue[option?.label ?? ''] =
                            option!.copyWith(inputValue: value);
                      }
                      onSelectProductAddons?.call(selectedValue);
                    },
                  ),
                  if (option?.description?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        option?.description ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11),
                      ),
                    ),
                  if (index != (item.options?.length ?? 0 - 1))
                    const SizedBox(height: 15),
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}
