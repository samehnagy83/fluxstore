import 'package:flutter/material.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

import '../helper.dart';

class YITHBadgeAdvanced5 extends StatelessWidget {
  const YITHBadgeAdvanced5(
      {super.key,
      required this.badge,
      required this.salePercent,
      required this.saleAmount});

  final YITHBadge badge;
  final int salePercent;
  final String saleAmount;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: YITHBadgeHelper.getAlignmentByBadge(badge) ??
          AlignmentDirectional.center,
      child: Container(
        width: 80,
        height: 80,
        decoration: ShapeDecoration(
          color: badge.backgroundColor,
          shape: const StarBorder(
            points: 15,
            innerRadiusRatio: 0.85,
            pointRounding: 0.4,
            valleyRounding: 0.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badge.advancedDisplay == YITHBadgeAdvancedDisplay.percentage
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      YITHBadgeHelper.textBadge(
                          '${salePercent.abs()}', 24, badge.textColor),
                      const SizedBox(width: 3),
                      YITHBadgeHelper.textBadge(
                          '%', 14, badge.textColor, false),
                    ],
                  )
                : YITHBadgeHelper.textBadge(saleAmount, 14, badge.textColor),
            const SizedBox(height: 3),
            YITHBadgeHelper.textBadge('OFF', 14, badge.textColor, false),
          ],
        ),
      ),
    );
  }
}
