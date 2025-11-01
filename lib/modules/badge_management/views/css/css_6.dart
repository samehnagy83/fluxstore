import 'package:flutter/material.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

class YITHBadgeCSS6 extends StatelessWidget {
  const YITHBadgeCSS6({super.key, required this.badge, required this.child});
  final YITHBadge badge;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: child,
        ),
        Positioned(
          bottom: -3,
          left: 0,
          right: 0,
          child: Container(height: 3, color: badge.backgroundColor),
        ),
      ],
    );
  }
}
