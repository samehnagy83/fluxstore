import 'package:inspireui/inspireui.dart';

import 'dynamic_link_service_config.dart';

class FluxDynamicLinkConfig extends DynamicLinkServiceConfig {
  /// Unique public key identifier for the app's deep link configuration
  final String publicKey;

  /// Domain name used for universal links (iOS) and app links (Android)
  /// This domain should host the apple-app-site-association and assetlinks.json files
  final String domainName;

  /// Custom URL scheme for deep linking (e.g., fluxstore://product/123)
  /// Used when universal/app links are not available
  final String scheme;

  /// Android package name - must match the package name in android/app/build.gradle
  /// Used for Android App Links verification
  final String androidPackage;

  /// App store url of your app, when set if the app is not installed,
  ///  it will redirect the user to app store, if not set, if will redirect user to fallback link
  final String? iosUrl;

  /// Play store url of your app, when set if the app is not installed,
  ///  it will redirect the user to play store, if not set, if will redirect user to fallback link
  final String? androidUrl;

  String createDeepLink(String code) {
    return '$scheme://$domainName/$code';
  }

  String createShortLink(String slug) {
    return '$linkDomain/l/$slug';
  }

  String get linkDomain {
    return 'https://$domainName';
  }

  FluxDynamicLinkConfig({
    required this.publicKey,
    required this.domainName,
    required this.scheme,
    required this.androidPackage,
    this.iosUrl,
    this.androidUrl,
  });

  @override
  bool get allowShareLink => true;

  @override
  Map<String, dynamic> toJson() {
    return {
      'publicKey': publicKey,
      'domainName': domainName,
      'androidPackage': androidPackage,
      'scheme': scheme,
      'androidUrl': androidUrl,
      'iosUrl': iosUrl,
    };
  }

  factory FluxDynamicLinkConfig.fromJson(Map<String, dynamic> map) {
    return FluxDynamicLinkConfig(
      publicKey: map['publicKey']?.toString() ?? '',
      domainName: map['domainName']?.toString() ?? '',
      androidPackage: map['androidPackage']?.toString() ?? '',
      scheme: map['scheme']?.toString() ?? '',
      androidUrl: map['androidUrl']?.toString(),
      iosUrl: map['iosUrl']?.toString(),
    );
  }

  bool get isValidate {
    return [publicKey, domainName, scheme, androidPackage]
            .any((e) => e.isEmptyOrNull) ==
        false;
  }
}
