import 'package:flutter/material.dart';

import '../../../models/entities/index.dart';
import 'yith_base_item.dart';
import 'yith_option_label.dart';

class YithRadioItem extends StatelessWidget {
  const YithRadioItem({
    super.key,
    required this.item,
    required this.basePrice,
    required this.selected,
    this.onSelectProductAddons,
  });

  final YithProductAddons item;
  final double basePrice;
  final Map<String, YithAddonsOption> selected;
  final void Function(Map<String, YithAddonsOption>)? onSelectProductAddons;

  @override
  Widget build(BuildContext context) {
    final selectedValue = Map<String, YithAddonsOption>.from(selected);
    var groupValue = selectedValue.values.firstOrNull;

    return SizedBox(
      width: double.infinity,
      child: YithBaseItem(
        item: item,
        child: RadioGroup<YithAddonsOption?>(
          groupValue: groupValue,
          onChanged: (YithAddonsOption? value) {
            if (value == null) return;
            selectedValue.clear();
            selectedValue[value.label ?? ''] = value;
            onSelectProductAddons?.call(selectedValue);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(item.options?.length ?? 0, (index) {
                final option = item.options?[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 24, // or shrink-wrap size
                          width: 24,
                          child: Radio<YithAddonsOption?>(
                            value: option,
                            materialTapTargetSize: MaterialTapTargetSize
                                .shrinkWrap, // reduces tap target
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            YithOptionLabel(
                              option: option,
                              basePrice: basePrice,
                            ),
                            if (option?.description?.isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.only(top: 3.0),
                                child: Text(
                                  option?.description ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 11),
                                ),
                              ),
                          ],
                        )),
                      ],
                    ),
                    if (index != (item.options?.length ?? 0 - 1))
                      const SizedBox(height: 15),
                  ],
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}
