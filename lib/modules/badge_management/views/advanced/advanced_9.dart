import 'package:flutter/material.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

import '../helper.dart';

class YITHBadgeAdvanced9 extends StatelessWidget {
  const YITHBadgeAdvanced9(
      {super.key,
      required this.badge,
      required this.salePercent,
      required this.saleAmount});

  final YITHBadge badge;
  final int salePercent;
  final String saleAmount;

  @override
  Widget build(BuildContext context) {
    var widthShape = 70.0;
    var heightShape = 80.0;

    return Align(
      alignment: YITHBadgeHelper.getAlignmentByBadge(badge) ??
          AlignmentDirectional.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 45),
              ClipPath(
                clipper: BannerClipper(),
                child: Container(
                  height: 25,
                  width: 100,
                  decoration: BoxDecoration(
                    color: YITHBadgeHelper.darkColor(
                        badge.backgroundColor ?? Colors.red),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: widthShape,
            height: heightShape,
            decoration: BoxDecoration(
              color: Colors.grey[800],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              Container(
                height: 25,
                width: 80,
                decoration: BoxDecoration(
                  color: badge.backgroundColor ?? Colors.red,
                ),
              ),
            ],
          ),
          Container(
            width: widthShape,
            height: heightShape,
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    YITHBadgeHelper.textBadge(
                        '${salePercent.abs()}', 24, badge.textColor),
                    YITHBadgeHelper.textBadge('%', 20, badge.textColor, false),
                  ],
                ),
                const SizedBox(height: 10),
                YITHBadgeHelper.textBadge(
                    'ON SALE', 15, badge.textColor, false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 13 / 14, size.height / 2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(size.width * 1 / 14, size.height / 2);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(BannerClipper oldClipper) => false;
}
