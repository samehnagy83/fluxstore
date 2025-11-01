import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

class YITHBadgeCSS4 extends StatelessWidget {
  const YITHBadgeCSS4({super.key, required this.badge, required this.child});
  final YITHBadge badge;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          right: 0,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                var size = constraints.maxWidth;
                var sizeSquare = size / math.sqrt(2);
                return Transform(
                  transform: Matrix4.identity()..rotateZ(math.pi / 4),
                  alignment: FractionalOffset.center,
                  child: Container(
                    width: sizeSquare,
                    height: sizeSquare,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(sizeSquare * 0.05),
                      color: badge.backgroundColor ?? HexColor('#f68d36'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(padding: const EdgeInsets.all(15), child: child),
      ],
    );
  }
}
