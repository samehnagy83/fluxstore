import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

class YITHBadgeCSS2 extends StatelessWidget {
  const YITHBadgeCSS2({super.key, required this.badge, required this.child});
  final YITHBadge badge;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        SizedBox(
          width: 65,
          height: 65,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                    width: 65,
                    color: badge.backgroundColor ?? HexColor('#48c293')),
                bottom: const BorderSide(width: 65, color: Colors.transparent),
              ),
            ),
          ),
        ),
        Positioned(
          top: -20,
          left: 9,
          child: Transform.rotate(
            angle: math.pi / 4,
            alignment: FractionalOffset.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }
}
