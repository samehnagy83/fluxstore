import 'package:flutter/material.dart';

import '../../../../models/entities/badge_management/yith_badge.dart';
import '../helper.dart';

class YITHBadgeAdvanced10 extends StatelessWidget {
  const YITHBadgeAdvanced10(
      {super.key,
      required this.badge,
      required this.salePercent,
      required this.saleAmount});

  final YITHBadge badge;
  final int salePercent;
  final String saleAmount;

  @override
  Widget build(BuildContext context) {
    var widthShape = 80.0;
    var heightShape = 80.0;

    return Align(
      alignment: YITHBadgeHelper.getAlignmentByBadge(badge) ??
          AlignmentDirectional.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: CircleClipClipper(),
            child: Container(
              clipBehavior: Clip.antiAlias,
              width: widthShape,
              height: heightShape,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.backgroundColor ?? Colors.red,
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        alignment: Alignment.centerRight,
                        width: double.infinity,
                        height: 25,
                        padding: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: YITHBadgeHelper.darkColor(
                              badge.backgroundColor ?? Colors.red),
                        ),
                        child: YITHBadgeHelper.textBadge(
                            'SALE!', 13, badge.textColor, false),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          YITHBadgeHelper.textBadge(
                              '$salePercent', 24, badge.textColor),
                          const SizedBox(width: 3),
                          YITHBadgeHelper.textBadge(
                              '%', 14, badge.textColor, false),
                        ],
                      ),
                    ],
                  ),
                  ClipPath(
                    clipper: ArcClipper(),
                    child: Container(
                      width: widthShape,
                      height: heightShape,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          transform: GradientRotation(3.14 / 5),
                          colors: [
                            Colors.black,
                            Colors.white,
                            Colors.black,
                          ],
                          stops: [0.0, 0.2, 0.5],
                          tileMode: TileMode.clamp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircleClipClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(size.width / 2.5, 0);
    path.addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2));
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CircleClipClipper oldClipper) => false;
}

class ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.addOval(Rect.fromCircle(
        center: Offset(size.width / 16, size.height / 6),
        radius: size.width / 2.8));
    return path;
  }

  @override
  bool shouldReclip(ArcClipper oldClipper) => false;
}
