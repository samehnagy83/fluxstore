import 'package:flutter/material.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

class YITHBadgeAdvanced3 extends StatelessWidget {
  const YITHBadgeAdvanced3(
      {super.key,
      required this.badge,
      required this.salePercent,
      required this.saleAmount});
  final YITHBadge badge;
  final int salePercent;
  final String saleAmount;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          color: badge.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            badge.advancedDisplay == YITHBadgeAdvancedDisplay.percentage
                ? '$salePercent%'
                : saleAmount,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(
                  fontWeight: FontWeight.w700,
                  color: badge.textColor ?? Colors.white,
                )
                .apply(fontSizeFactor: 0.9),
          ),
        ),
        Positioned(
          bottom: -6,
          left: 0,
          right: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 6, color: Colors.red),
                    left: BorderSide(width: 6, color: Colors.transparent),
                    right: BorderSide(width: 6, color: Colors.transparent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
