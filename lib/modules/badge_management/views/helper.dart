import 'package:flutter/material.dart';
import '../../../models/entities/badge_management/yith_badge.dart';

class YITHBadgeHelper {
  static Color darkColor(Color color, [double factor = 0.4]) {
    var red = (color.r * (1.0 - factor)).round();
    var green = (color.g * (1.0 - factor)).round();
    var blue = (color.b * (1.0 - factor)).round();
    return Color.fromRGBO(red, green, blue, 1);
  }

  static AlignmentDirectional? getAlignmentByBadge(YITHBadge badge) {
    var position = badge.position;
    var alignment = badge.alignment;
    if (position == YITHBadgePosition.top) {
      if (alignment == YITHBadgeAlignment.left) {
        return AlignmentDirectional.topStart;
      }
      if (alignment == YITHBadgeAlignment.center) {
        return AlignmentDirectional.topCenter;
      }
      if (alignment == YITHBadgeAlignment.right) {
        return AlignmentDirectional.topEnd;
      }
    }

    if (position == YITHBadgePosition.middle) {
      if (alignment == YITHBadgeAlignment.left) {
        return AlignmentDirectional.centerStart;
      }
      if (alignment == YITHBadgeAlignment.center) {
        return AlignmentDirectional.center;
      }
      if (alignment == YITHBadgeAlignment.right) {
        return AlignmentDirectional.centerEnd;
      }
    }

    if (position == YITHBadgePosition.bottom) {
      if (alignment == YITHBadgeAlignment.left) {
        return AlignmentDirectional.bottomStart;
      }
      if (alignment == YITHBadgeAlignment.center) {
        return AlignmentDirectional.bottomCenter;
      }
      if (alignment == YITHBadgeAlignment.right) {
        return AlignmentDirectional.bottomEnd;
      }
    }

    return null;
  }

  static Widget textBadge(String text, double fontSize, Color? backgroundColor,
      [bool isBold = true]) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
        color: backgroundColor ?? Colors.white,
      ),
    );
  }
}
