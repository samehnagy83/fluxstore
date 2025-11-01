import '../../constants.dart';

enum WebViewMode {
  /// https://pub.dev/packages/flutter_inappwebview
  inAppWebView,

  /// https://pub.dev/packages/webview_flutter
  webViewFlutter,
  ;

  static WebViewMode fromString(String? mode) {
    return WebViewMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => WebViewMode.webViewFlutter,
    );
  }
}

class WebViewConfig {
  final WebViewMode webViewMode;
  final String webViewScript;
  final bool alwaysClearWebViewCache;
  final bool alwaysClearWebViewCookie;

  /// List of domains that should open the external app instead of the webview.
  /// Just add the domain name only, do not add full URL. For example: "example.com"
  /// If not set, we will use our default list from [kExternalDomains]
  final List<String> externalDomains;

  /// List of domains that should be loaded in the webview.
  /// If the list is empty, all domains will be opened in the webview if it is
  /// not in [externalDomains]. Otherwise, if the domain is not in this list, it
  /// will be opened in the external browser.
  /// Just add the domain name only, do not add full URL. For example: "example.com"
  final List<String> internalDomains;

  bool get isInAppWebView => webViewMode == WebViewMode.inAppWebView;
  bool get isWebViewFlutter => webViewMode == WebViewMode.webViewFlutter;

  const WebViewConfig({
    this.webViewMode = WebViewMode.webViewFlutter,
    this.webViewScript = '',
    this.alwaysClearWebViewCache = false,
    this.alwaysClearWebViewCookie = false,
    this.externalDomains = kExternalDomains,
    this.internalDomains = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'webViewMode': webViewMode.toString(),
      'webViewScript': webViewScript,
      'alwaysClearWebViewCache': alwaysClearWebViewCache,
      'alwaysClearWebViewCookie': alwaysClearWebViewCookie,
      'internalDomains': internalDomains,
    };
  }

  factory WebViewConfig.fromJson(Map<String, dynamic> json) {
    final externalDomains = json['externalDomains'];

    return WebViewConfig(
      webViewMode: WebViewMode.fromString('${json['webViewMode']}'),
      webViewScript: '${json['webViewScript']}',
      alwaysClearWebViewCache:
          bool.tryParse('${json['alwaysClearWebViewCache']}') ?? false,
      alwaysClearWebViewCookie:
          bool.tryParse('${json['alwaysClearWebViewCookie']}') ?? false,
      externalDomains: (externalDomains is List && externalDomains.isNotEmpty)
          ? List<String>.from(externalDomains)
          : kExternalDomains,
      internalDomains: json['internalDomains'] is List
          ? List<String>.from(json['internalDomains'])
          : [],
    );
  }
}
