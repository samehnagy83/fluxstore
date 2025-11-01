import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

import '../helper.dart';

class YITHBadgeCSS5 extends StatelessWidget {
  const YITHBadgeCSS5({super.key, required this.badge, required this.child});
  final YITHBadge badge;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          color: badge.backgroundColor,
          padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
          margin: const EdgeInsets.only(left: 25),
          child: child,
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: 25,
          child: LayoutBuilder(
            builder: (_, BoxConstraints constraints) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        width: 25,
                        color: badge.backgroundColor ?? HexColor('#2e91a3')),
                    bottom: BorderSide(
                        width: constraints.maxHeight,
                        color: Colors.transparent),
                  ),
                ),
              );
            },
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
                  left: const BorderSide(width: 2, color: Colors.transparent),
                  right: const BorderSide(width: 5, color: Colors.transparent),
                  top: BorderSide(
                      width: 6,
                      color: YITHBadgeHelper.darkColor(
                          badge.backgroundColor ?? HexColor('#2e91a3'))),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
