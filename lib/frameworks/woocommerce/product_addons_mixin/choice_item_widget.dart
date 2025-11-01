import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../../common/tools/price_tools.dart';
import '../../../models/index.dart';
import 'expansion_tile_widget.dart';

class ChoiceItemWidget extends StatelessWidget {
  final ProductAddons item;
  final Map<String, AddonsOption> selected;
  final void Function(Map<String, AddonsOption>)? onSelectProductAddons;
  final String? durationUnit;
  const ChoiceItemWidget({
    required this.item,
    required this.selected,
    this.onSelectProductAddons,
    this.durationUnit,
  });

  void onTapItem(AddonsOption? option) {
    final value = Map<String, AddonsOption>.from(selected);
    final label = option?.label;
    switch (item.type) {
      case AddonsType.radiobutton:
      case AddonsType.multiple_choice:
        value.clear();
        if (label != null && option != null) {
          value[label] = option;
        }
        break;
      case AddonsType.checkbox:
        final isSelected = value[label] != null;
        if (isSelected) {
          value.remove(label);
        } else {
          if (label != null && option != null) {
            value[label] = option;
          }
        }
        break;
      default:
    }
    onSelectProductAddons?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTileWidget(
      item: item,
      selected: selected,
      durationUnit: durationUnit,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(text: item.name ?? '', children: [
              if (item.required ?? true)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
            ]),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: selected.isNotEmpty
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValueOpacity(0.7),
                ),
          ),
          if ((item.required ?? false) && (item.type?.isRadio ?? false))
            Text(
              S.of(context).mustSelectOneItem,
              style: TextStyle(
                fontSize: 10,
                color: selected.isNotEmpty
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValueOpacity(0.7),
              ),
            ),
        ],
      ),
      subtitle: selected.keys.join(', '),
      children: [
        RadioGroup<String?>(
          groupValue: selected.keys.isNotEmpty ? selected.keys.first : null,
          onChanged: (val) {},
          child: Wrap(
            children: [
              if (!(item.required ?? false) && item.type != AddonsType.checkbox)
                ChoiceItem(
                  isSelected: selected.isEmpty,
                  option: AddonsOption(
                    type: item.type,
                  ),
                  label: S.of(context).none,
                  onTap: () => onTapItem(null),
                ),
              ...List.generate(item.options?.length ?? 0, (index) {
                final option = item.options?[index];
                final isSelected = selected[option?.label] != null;
                return ChoiceItem(
                  option: option,
                  isSelected: isSelected,
                  onTap: () => onTapItem(option),
                  showPrice: !(item.hidePrice ?? false),
                  showDuration: !(item.hideDuration ?? false),
                );
              })
            ],
          ),
        ),
      ],
    );
  }
}

class ChoiceItem extends StatelessWidget {
  final AddonsOption? option;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool? showPrice;
  final bool? showDuration;
  final String? durationUnit;
  final String? label;

  const ChoiceItem({
    this.option,
    this.isSelected = false,
    this.onTap,
    this.showPrice,
    this.showDuration,
    this.durationUnit,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final model = context.read<AppModel>();
    final rates = model.currencyRate;
    final currency = model.currency;
    final langCode = model.langCode;
    final duration = int.tryParse('${option?.duration}') ?? 0;
    final price = double.tryParse('${option?.price}') ?? 0.0;
    final priceText = PriceTools.getCurrencyFormatted(
      option?.price,
      rates,
      currency: currency,
    );
    final durationText =
        TimeAgo.toUnitString(duration, unit: durationUnit, langCode: langCode);
    return Container(
      constraints: BoxConstraints(
        minWidth: MediaQuery.sizeOf(context).width * 0.4,
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (option?.type?.isRadio ?? false)
              IgnorePointer(
                child: Radio<String?>(
                  visualDensity: VisualDensity.compact,
                  value: option?.label,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),
            if (option?.type == AddonsType.checkbox)
              IgnorePointer(
                child: Checkbox(
                  visualDensity: VisualDensity.compact,
                  onChanged: (_) => onTap?.call(),
                  activeColor: Theme.of(context).primaryColor,
                  checkColor: Colors.white,
                  value: isSelected,
                ),
              ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '${label ?? option?.label}',
                  children: [
                    TextSpan(
                      children: [
                        if ((showPrice ?? true) && price > 0)
                          TextSpan(
                            text: '  ($priceText)',
                          ),
                        if ((showDuration ?? true) && duration > 0)
                          TextSpan(
                            text: ' + $durationText',
                          )
                      ],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
