import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

class YITHBadgeCSS1 extends StatelessWidget {
  const YITHBadgeCSS1({super.key, required this.badge, required this.child});
  final YITHBadge badge;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: badge.padding,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          color: badge.backgroundColor ?? HexColor('#3a86c4'),
          child: child,
        ),
      ],
    );
  }
}
