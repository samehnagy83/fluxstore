import 'package:flutter/material.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

import '../helper.dart';

class YITHBadgeAdvanced4 extends StatelessWidget {
  const YITHBadgeAdvanced4(
      {super.key,
      required this.badge,
      required this.salePercent,
      required this.saleAmount});

  final YITHBadge badge;
  final int salePercent;
  final String saleAmount;

  @override
  Widget build(BuildContext context) {
    const width = 120.0;
    const height = width / 4;
    return Stack(
      children: [
        Positioned.fill(
          top: width / 8,
          right: (width / 4) * (-1),
          child: Align(
            alignment: YITHBadgeHelper.getAlignmentByBadge(badge) ??
                AlignmentDirectional.center,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(45 / 360),
              child: ClipPath(
                clipper: QuadrangleClipper(),
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: badge.backgroundColor,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      badge.advancedDisplay ==
                              YITHBadgeAdvancedDisplay.percentage
                          ? YITHBadgeHelper.textBadge(
                              '$salePercent%', 12, badge.textColor)
                          : YITHBadgeHelper.textBadge(
                              saleAmount, 12, badge.textColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QuadrangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(size.width / 4, 0);
    path.lineTo(size.width * 3 / 4, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(size.width / 4, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(QuadrangleClipper oldClipper) => false;
}
