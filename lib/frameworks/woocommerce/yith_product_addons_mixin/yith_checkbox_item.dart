import 'package:flutter/material.dart';

import '../../../models/entities/index.dart';
import 'yith_base_item.dart';
import 'yith_option_label.dart';

class YithCheckboxItem extends StatelessWidget {
  const YithCheckboxItem(
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
                  Row(
                    children: <Widget>[
                      SizedBox(
                        height: 24, // or shrink-wrap size
                        width: 24,
                        child: Checkbox(
                          value: selectedValue[option?.label ?? ''] != null,
                          onChanged: (bool? value) {
                            if (value == null) return;
                            final label = option?.label;
                            if (label != null && option != null) {
                              if (value) {
                                selectedValue[label] = option;
                              } else {
                                selectedValue.remove(label);
                              }
                            }
                            onSelectProductAddons?.call(selectedValue);
                          },
                          materialTapTargetSize: MaterialTapTargetSize
                              .shrinkWrap, // reduces tap target
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: YithOptionLabel(
                          option: option,
                          basePrice: basePrice,
                        ),
                      ),
                    ],
                  ),
                  if (option?.description?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 3.0),
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
