import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

class YITHBadgeCSS3 extends StatelessWidget {
  const YITHBadgeCSS3({super.key, required this.badge, required this.child});
  final YITHBadge badge;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: badge.backgroundColor ?? Colors.white,
        border: Border.all(width: 2, color: HexColor('#94c119')),
        borderRadius: BorderRadius.circular(7),
      ),
      child: child,
    );
  }
}
