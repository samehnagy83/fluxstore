import 'package:flutter/material.dart';
import 'package:inspireui/extensions.dart';

import '../../../../models/entities/badge_management/yith_badge.dart';
import '../helper.dart';

class YITHBadgeAdvanced7 extends StatelessWidget {
  const YITHBadgeAdvanced7(
      {super.key,
      required this.badge,
      required this.salePercent,
      required this.saleAmount});

  final YITHBadge badge;
  final int salePercent;
  final String saleAmount;

  @override
  Widget build(BuildContext context) {
    final listStops = <double>[0, 0.65, 0.65, 1.0];
    final listColors = [
      badge.backgroundColor ?? Colors.red.withValueOpacity(0.5),
      badge.backgroundColor ?? Colors.red.withValueOpacity(0.5),
      YITHBadgeHelper.darkColor(badge.backgroundColor ?? Colors.red, 0.3),
      YITHBadgeHelper.darkColor(badge.backgroundColor ?? Colors.red, 0.3),
    ];
    final boxDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: listStops,
        colors: listColors,
        transform: const GradientRotation(-0.20),
      ),
    );
    return Align(
      alignment: YITHBadgeHelper.getAlignmentByBadge(badge) ??
          AlignmentDirectional.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipPath(
            clipper: QuadrangleClipper(),
            child: Container(
              width: 100,
              height: 80,
              decoration: boxDecoration,
              padding: EdgeInsets.only(
                  left: 18,
                  top: badge.advancedDisplay ==
                          YITHBadgeAdvancedDisplay.percentage
                      ? 12
                      : 18,
                  bottom: 9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  badge.advancedDisplay == YITHBadgeAdvancedDisplay.percentage
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            YITHBadgeHelper.textBadge(
                                '${salePercent.abs()}', 30, badge.textColor),
                            const SizedBox(width: 5),
                            YITHBadgeHelper.textBadge(
                                '%', 16, badge.textColor, false),
                          ],
                        )
                      : YITHBadgeHelper.textBadge(
                          saleAmount, 18, badge.textColor),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: YITHBadgeHelper.textBadge(
                        'OFF', 15, badge.textColor, false),
                  ),
                ],
              ),
            ),
          ),
          Transform(
            alignment: FractionalOffset.topRight,
            transform: Matrix4.rotationZ(0.174533),
            child: ClipPath(
              clipper: TriangleClipper90(),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: YITHBadgeHelper.darkColor(
                        badge.backgroundColor ?? Colors.red, 0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuadrangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, 0);
    path.lineTo(size.width, size.height * 2 / 10);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 4, size.height * 9 / 10);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(QuadrangleClipper oldClipper) => false;
}

class TriangleClipper90 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(TriangleClipper90 oldClipper) => false;
}
