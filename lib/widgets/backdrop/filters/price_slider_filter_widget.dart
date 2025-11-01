import 'dart:math';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../common/constants.dart';
import '../../../common/tools/price_tools.dart';
import '../../../models/app_model.dart';
import '../../../services/services.dart';
import 'widgets/menu_title_widget.dart';

class PriceSliderFilterWidget extends StatefulWidget {
  const PriceSliderFilterWidget({
    super.key,
    this.currentMinPrice,
    this.currentMaxPrice,
    this.minFilterPrice,
    this.maxFilterPrice,
    this.onChanged,
    this.useExpansionStyle = true,
  });

  final double? currentMinPrice;
  final double? currentMaxPrice;
  final double? minFilterPrice;
  final double? maxFilterPrice;
  final void Function(double, double)? onChanged;
  final bool useExpansionStyle;

  @override
  State<PriceSliderFilterWidget> createState() =>
      _PriceSliderFilterWidgetState();
}

class _PriceSliderFilterWidgetState extends State<PriceSliderFilterWidget> {
  AppModel get appModel => context.read<AppModel>();

  // Default values
  double get minFilterPrice =>
      min(_currentMinPrice, widget.minFilterPrice ?? 0);
  double get maxFilterPrice =>
      max(_currentMaxPrice, widget.maxFilterPrice ?? kMaxPriceFilter);

  double _currentMinPrice = 0.0;
  double _currentMaxPrice = 0.0;

  Widget _renderPrice(double price) {
    final currency = appModel.currency;
    final currencyRate = appModel.currencyRate;

    return Text(
      PriceTools.getCurrencyFormatted(price, currencyRate, currency: currency)!,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  void _update(RangeValues priceRange) {
    setState(() {
      _currentMinPrice = priceRange.start;
      _currentMaxPrice = priceRange.end;
    });
    EasyDebounce.debounce(
      'slider',
      const Duration(milliseconds: 1000),
      () {
        widget.onChanged?.call(_currentMinPrice, _currentMaxPrice);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _currentMinPrice = widget.currentMinPrice ?? 0;
    _currentMaxPrice = widget.currentMaxPrice ?? kMaxPriceFilter;
  }

  @override
  void didUpdateWidget(PriceSliderFilterWidget oldWidget) {
    if (oldWidget.currentMinPrice != widget.currentMinPrice) {
      _currentMinPrice = widget.currentMinPrice ?? 0;
    }

    if (oldWidget.currentMaxPrice != widget.currentMaxPrice) {
      _currentMaxPrice = widget.currentMaxPrice ?? kMaxPriceFilter;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Services().widget.enableProductBackdrop
        ? Colors.white
        : theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;
    final primaryColorLight = theme.primaryColorLight;

    final child = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_currentMinPrice != 0 || _currentMaxPrice != 0) ...[
              _renderPrice(_currentMinPrice),
              Text(
                ' - ',
                style: TextStyle(fontSize: 16, color: secondaryColor),
              ),
            ],
            _renderPrice(_currentMaxPrice),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: primaryColor,
            inactiveTrackColor: primaryColorLight.withValues(alpha: 0.5),
            activeTickMarkColor: primaryColorLight,
            inactiveTickMarkColor: secondaryColor.withValues(alpha: 0.5),
            overlayColor: primaryColor.withValues(alpha: 0.2),
            thumbColor: primaryColor,
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: RangeSlider(
            min: minFilterPrice,
            max: maxFilterPrice,
            divisions: kFilterDivision,
            values: RangeValues(_currentMinPrice, _currentMaxPrice),
            onChanged: _update,
          ),
        ),
      ],
    );

    return MenuTitleWidget(
      title: S.of(context).price,
      useExpansionStyle: widget.useExpansionStyle,
      child: child,
    );
  }
}
