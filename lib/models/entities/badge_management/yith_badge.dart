import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:inspireui/utils/colors.dart';

import 'extensions/map_extension.dart';
import 'yith_badge_size.dart';

enum YITHBadgeType { text, image, css, advanced }

extension YITHBadgeTypeX on YITHBadgeType {
  static YITHBadgeType? initFrom(String? value) {
    return YITHBadgeType.values
        .firstWhereOrNull((YITHBadgeType e) => e.name == value);
  }
}

enum YITHBadgePosition { top, middle, bottom }

extension YITHBadgePositionX on YITHBadgePosition {
  static YITHBadgePosition? initFrom(String? value) {
    return YITHBadgePosition.values
        .firstWhereOrNull((YITHBadgePosition e) => e.name == value);
  }
}

enum YITHBadgeAlignment { left, center, right }

extension YITHBadgeAlignmentX on YITHBadgeAlignment {
  static YITHBadgeAlignment? initFrom(String? value) {
    return YITHBadgeAlignment.values
        .firstWhereOrNull((YITHBadgeAlignment e) => e.name == value);
  }
}

enum YITHBadgeAdvancedDisplay { amount, percentage }

extension YITHBadgeAdvancedDisplayX on YITHBadgeAdvancedDisplay {
  static YITHBadgeAdvancedDisplay? initFrom(String? value) {
    return YITHBadgeAdvancedDisplay.values
        .firstWhereOrNull((YITHBadgeAdvancedDisplay e) => e.name == value);
  }
}

class YITHBadge {
  const YITHBadge(
      {this.type,
      this.text,
      this.backgroundColor,
      this.textColor,
      this.size,
      this.padding,
      this.margin,
      this.borderRadius,
      this.opacity,
      this.position,
      this.alignment,
      this.imageUrl,
      this.css,
      this.advanced,
      this.advancedDisplay});

  final YITHBadgeType? type;
  final String? text;
  final Color? backgroundColor;
  final Color? textColor;
  final YITHBadgeSize? size;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? opacity;
  final YITHBadgePosition? position;
  final YITHBadgeAlignment? alignment;
  final String? imageUrl;
  final String? css;
  final String? advanced;
  final YITHBadgeAdvancedDisplay? advancedDisplay;

  factory YITHBadge.fromJson(Map<String?, dynamic> json) {
    final p = YITHBadgePositionX.initFrom(json['position']);
    final a = YITHBadgeAlignmentX.initFrom(json['alignment']);
    final opacity = double.tryParse(json['opacity'].toString());
    final borderRadius = json['border_radius']?['dimensions'];
    final margin = json['margin']?['dimensions'];
    final padding = json['padding']?['dimensions'];
    final size = json['size'];

    HexColor? parseColor(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return HexColor(value);
      }
      return null;
    }

    return YITHBadge(
      text: json['text'],
      backgroundColor: parseColor(json['background_color']),
      textColor: parseColor(json['text_color']),
      type: YITHBadgeTypeX.initFrom(json['type']?.toString()),
      size: size is Map
          ? YITHBadgeSize.fromJson(Map<String?, dynamic>.from(size))
          : null,
      padding: padding is Map ? padding.toPadding() : null,
      margin: margin is Map ? margin.toMargin(p, a) : null,
      borderRadius: borderRadius is Map ? borderRadius.toBorderRadius() : null,
      opacity: opacity != null ? opacity / 100 : 1.0,
      position: p,
      alignment: a,
      imageUrl: json['image_url']?.toString(),
      css: json['css']?.toString(),
      advanced: json['advanced']?.toString(),
      advancedDisplay: YITHBadgeAdvancedDisplayX.initFrom(
          json['advanced_display']?.toString()),
    );
  }
}
