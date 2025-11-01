import 'package:flutter/material.dart';

import '../yith_badge.dart';

extension ConvertMapToPadding on Map {
  EdgeInsetsGeometry toPadding() {
    return EdgeInsets.zero.copyWith(
      top: double.tryParse(this['top'].toString()),
      bottom: double.tryParse(this['bottom'].toString()),
      left: double.tryParse(this['left'].toString()),
      right: double.tryParse(this['right'].toString()),
    );
  }

  EdgeInsetsGeometry toMargin(
      YITHBadgePosition? position, YITHBadgeAlignment? alignment) {
    var margin = EdgeInsets.zero;
    final top = double.tryParse(this['top'].toString());
    if (top != null && position != YITHBadgePosition.bottom) {
      margin = margin.copyWith(top: top);
    }
    final left = double.tryParse(this['left'].toString());
    if (left != null && alignment != YITHBadgeAlignment.right) {
      margin = margin.copyWith(left: left);
    }
    final bottom = double.tryParse(this['bottom'].toString());
    if (bottom != null && position == YITHBadgePosition.bottom) {
      margin = margin.copyWith(bottom: bottom);
    }
    final right = double.tryParse(this['right'].toString());
    if (right != null && alignment == YITHBadgeAlignment.right) {
      margin = margin.copyWith(right: right);
    }

    return margin;
  }

  BorderRadius toBorderRadius() {
    var borderRadius = BorderRadius.zero;
    if (this['top-left'] != null && double.tryParse(this['top-left']) != null) {
      borderRadius = borderRadius.copyWith(
          topLeft: Radius.circular(double.parse(this['top-left'])));
    }
    if (this['top-right'] != null &&
        double.tryParse(this['top-right']) != null) {
      borderRadius = borderRadius.copyWith(
          topRight: Radius.circular(double.parse(this['top-right'])));
    }
    if (this['bottom-right'] != null &&
        double.tryParse(this['bottom-right']) != null) {
      borderRadius = borderRadius.copyWith(
          bottomRight: Radius.circular(double.parse(this['bottom-right'])));
    }
    if (this['bottom-left'] != null &&
        double.tryParse(this['bottom-left']) != null) {
      borderRadius = borderRadius.copyWith(
          bottomLeft: Radius.circular(double.parse(this['bottom-left'])));
    }

    return borderRadius;
  }
}
