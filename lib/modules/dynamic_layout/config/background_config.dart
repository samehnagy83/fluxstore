import 'package:flutter/widgets.dart';

import '../helper/helper.dart';

class BackgroundConfig {
  String? color;
  String? image;
  double height = 0.0;
  String? layout;
  bool isScrollable = false;
  String? video;
  BoxFit? fit;

  BackgroundConfig({
    this.color,
    this.image,
    this.height = 0.0,
    this.layout,
    this.isScrollable = false,
    this.video,
    this.fit,
  });

  BackgroundConfig.fromJson(dynamic json) {
    color = json['color'];
    image = json['image'];
    height = Helper.formatDouble(json['height']) ?? 0.0;
    layout = json['layout'];
    isScrollable = json['isScrollable'] ?? false;
    video = json['video'];
    fit = Helper.boxFit(json['fit']);
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['color'] = color;
    map['image'] = image;
    map['height'] = height;
    map['layout'] = layout;
    map['isScrollable'] = isScrollable;
    map['video'] = video;
    map['fit'] = fit?.name;
    return map;
  }
}
