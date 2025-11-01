class OfflineModeConfig {
  final bool enable;
  // final List<String> excludeEndpoint;

  const OfflineModeConfig({
    this.enable = false,
    // this.excludeEndpoint = const [],
  });

  factory OfflineModeConfig.fromJson(Map<String, dynamic> json) {
    return OfflineModeConfig(
      enable: json['enable'] ?? false,
      // excludeEndpoint: json['excludeEndpoint'] is List
      //     ? List<String>.from(json['excludeEndpoint'])
      //     : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable': enable,
      // 'excludeEndpoint': excludeEndpoint,
    };
  }

  OfflineModeConfig copyWith({
    bool? enable,
    // List<String>? excludeEndpoint,
  }) {
    return OfflineModeConfig(
      enable: enable ?? this.enable,
      // excludeEndpoint: excludeEndpoint ?? this.excludeEndpoint,
    );
  }
}
