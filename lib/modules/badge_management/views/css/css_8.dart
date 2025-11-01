import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

import '../helper.dart';

class YITHBadgeCSS8 extends StatelessWidget {
  const YITHBadgeCSS8({super.key, required this.badge, required this.child});
  final YITHBadge badge;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    var isRTL = context.isRtl;
    var height = 26.0;

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Transform.rotate(
        angle: isRTL ? -0.785 : 0.785,
        alignment:
            isRTL ? FractionalOffset.bottomLeft : FractionalOffset.bottomRight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 100),
              height: height,
              color: badge.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              margin: EdgeInsets.only(left: height, right: height),
              child: child,
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(width: height, color: Colors.transparent),
                    bottom: BorderSide(
                        width: height,
                        color: badge.backgroundColor ?? HexColor('#e73e08')),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(width: height, color: Colors.transparent),
                    bottom: BorderSide(
                        width: height,
                        color: badge.backgroundColor ?? HexColor('#e73e08')),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              right: 0,
              child: SizedBox(
                width: 7,
                height: 6,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left:
                          const BorderSide(width: 6, color: Colors.transparent),
                      top: BorderSide(
                          width: 6,
                          color: YITHBadgeHelper.darkColor(
                              badge.backgroundColor ?? HexColor('#e73e08'))),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              left: 0,
              child: SizedBox(
                width: 7,
                height: 6,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right:
                          const BorderSide(width: 6, color: Colors.transparent),
                      top: BorderSide(
                          width: 6,
                          color: YITHBadgeHelper.darkColor(
                              badge.backgroundColor ?? HexColor('#e73e08'))),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
