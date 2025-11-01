import 'package:flutter/material.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

import '../helper.dart';

class YITHBadgeAdvanced8 extends StatelessWidget {
  const YITHBadgeAdvanced8(
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
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: MainBannerClipper(),
            child: Container(
              height: 100,
              width: 75,
              decoration: BoxDecoration(
                color: YITHBadgeHelper.darkColor(
                    badge.backgroundColor ?? Colors.red),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        YITHBadgeHelper.textBadge(
                            '${salePercent.abs()}', 24, badge.textColor),
                        YITHBadgeHelper.textBadge(
                            '%', 20, badge.textColor, false),
                      ],
                    ),
                    YITHBadgeHelper.textBadge(
                        'Save $saleAmount', 12, badge.textColor, false),
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ClipPath(
                clipper: SubBannerClipper(),
                child: Container(
                  height: 20,
                  width: 100,
                  decoration: BoxDecoration(
                    color: badge.backgroundColor ?? Colors.red,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      YITHBadgeHelper.textBadge(
                          'DISCOUNT', 13, badge.textColor, false)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MainBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height * 7 / 8);
    path.lineTo(0, size.height);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(MainBannerClipper oldClipper) => false;
}

class SubBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 9 / 10, size.height / 2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(size.width * 1 / 10, size.height / 2);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(SubBannerClipper oldClipper) => false;
}
