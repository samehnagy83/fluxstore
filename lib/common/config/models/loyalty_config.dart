import '../../../modules/dynamic_layout/helper/helper.dart';

class LoyaltyConfig {
  final bool enabled;
  final bool useTotalPointsForTier;
  final double usePointRateForOnePoint;
  final double addPointRateForOnePoint;
  final Map<String, int> levels;

  const LoyaltyConfig({
    this.enabled = false,
    this.useTotalPointsForTier = true,
    this.usePointRateForOnePoint = 1.0,
    this.addPointRateForOnePoint = 100.0,
    required this.levels,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'useTotalPointsForTier': useTotalPointsForTier,
      'usePointRateForOnePoint': usePointRateForOnePoint,
      'addPointRateForOnePoint': addPointRateForOnePoint,
      'levels': levels,
    };
  }

  factory LoyaltyConfig.fromJson(Map map) {
    return LoyaltyConfig(
      enabled: bool.tryParse('${map['enabled']}') ?? false,
      useTotalPointsForTier:
          bool.tryParse('${map['useTotalPointsForTier']}') ?? true,
      usePointRateForOnePoint:
          Helper.formatDouble(map['usePointRateForOnePoint']) ?? 1.0,
      addPointRateForOnePoint:
          Helper.formatDouble(map['addPointRateForOnePoint']) ?? 100,
      levels: map['levels'] is Map
          ? Map<String, int>.from(map['levels'])
          : <String, int>{},
    );
  }
}
