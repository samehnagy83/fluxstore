import 'package:flutter/material.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

import '../helper.dart';

class YITHBadgeAdvanced2 extends StatelessWidget {
  const YITHBadgeAdvanced2(
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
      child: Stack(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.backgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                badge.advancedDisplay == YITHBadgeAdvancedDisplay.percentage
                    ? YITHBadgeHelper.textBadge(
                        '${salePercent.abs()}%', 24, badge.textColor)
                    : YITHBadgeHelper.textBadge(
                        saleAmount, 20, badge.textColor),
                YITHBadgeHelper.textBadge('OFF', 12, badge.textColor, false),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 60,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(-45 / 360),
              child: ClipPath(
                clipper: TriangleClipper(),
                child: Container(
                  height: 20,
                  width: 20,
                  color: badge.backgroundColor,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height / 2);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height / 2);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}
