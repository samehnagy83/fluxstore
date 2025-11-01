import 'package:flutter/material.dart';
import 'package:inspireui/extensions.dart';

import '../../../../models/entities/badge_management/yith_badge.dart';
import '../helper.dart';

class YITHBadgeAdvanced1 extends StatelessWidget {
  const YITHBadgeAdvanced1(
      {super.key,
      required this.badge,
      required this.salePercent,
      required this.saleAmount});

  final YITHBadge badge;
  final int salePercent;
  final String saleAmount;

  @override
  Widget build(BuildContext context) {
    final listStops = <double>[0, 0.7, 0.7, 1.0];
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
      ),
    );

    return Padding(
      padding: badge.padding ?? const EdgeInsets.all(0),
      child: Stack(
        children: [
          Align(
            alignment: YITHBadgeHelper.getAlignmentByBadge(badge) ??
                AlignmentDirectional.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipPath(
                      clipper: TriangleClipper(clockwise: !context.isRtl),
                      child: Container(
                        height: 65,
                        width: 20,
                        decoration: boxDecoration,
                      ),
                    ),
                    Container(
                      height: 65,
                      width: 100,
                      decoration: boxDecoration,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5, top: 0),
                              child: Row(
                                children: [
                                  YITHBadgeHelper.textBadge(
                                      '${salePercent.abs()}',
                                      32,
                                      badge.textColor),
                                  const SizedBox(width: 5),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      YITHBadgeHelper.textBadge(
                                          '%', 12, badge.textColor, false),
                                      YITHBadgeHelper.textBadge(
                                          'OFF', 12, badge.textColor, false),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            YITHBadgeHelper.textBadge(
                                'Sale $saleAmount', 11, badge.textColor, false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ClipPath(
                  clipper: TriangleClipper90(clockwise: !context.isRtl),
                  child: Container(
                    height: 5,
                    width: 5,
                    color: YITHBadgeHelper.darkColor(
                        badge.backgroundColor ?? Colors.red, 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  final bool clockwise;

  TriangleClipper({this.clockwise = true});
  @override
  Path getClip(Size size) {
    final path = Path();
    if (clockwise) {
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();

    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}

class TriangleClipper90 extends CustomClipper<Path> {
  final bool clockwise;

  TriangleClipper90({this.clockwise = true});
  @override
  Path getClip(Size size) {
    final path = Path();
    if (clockwise) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(TriangleClipper90 oldClipper) => false;
}
