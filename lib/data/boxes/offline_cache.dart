part of '../boxes.dart';

class OfflineCacheBox extends FluxBox with PeriodicallyCleanMixin {
  static final _instance = OfflineCacheBox._internal();

  factory OfflineCacheBox() => _instance;

  OfflineCacheBox._internal();

  @override
  String get boxKey => BoxKeys.hiveOfflineCacheBox;
}
