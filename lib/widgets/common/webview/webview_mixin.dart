import 'package:flux_ui/flux_ui.dart';
import 'package:inspireui/inspireui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/config.dart';
import '../../../common/extensions/string_ext.dart';

mixin WebviewMixin {
  /// Return true when overridden and the navigation in webview should stop.
  ///
  /// `externalDomains` is list of domains that should open the external app
  /// instead of the webview.
  ///
  /// `internalDomains` is list of domains that should be loaded in the webview.
  /// If the list is empty, all domains will be opened in the webview if it is
  /// not in [externalDomains]. Otherwise, if the domain is not in this list, it
  /// will be opened in the external browser.
  Future<bool> shouldPreventWebNavigation(String url) async {
    if (url.startsWith('http')) {
      final internalDomains = kWebViewConfig.internalDomains;
      final externalDomains = kWebViewConfig.externalDomains;

      // If not configured, open all http sites in webview
      if (internalDomains.isEmpty && externalDomains.isEmpty) {
        return false;
      }

      // If `url` is in `internalDomains`, always open in webview
      if (internalDomains.isNotEmpty &&
          internalDomains.any(url.isTheSameDomain)) {
        return false;
      }

      // If `url` is on `externalDomains`, always open in external app/browser
      if (externalDomains.isNotEmpty &&
          externalDomains.any(url.isTheSameDomain)) {
        return _openExternalUrl(url);
      }

      // If `internalDomains` is configured, but `url` is not included then it
      // will open in external app/browser
      if (internalDomains.isNotEmpty &&
          !internalDomains.any(url.isTheSameDomain)) {
        return _openExternalUrl(url);
      }

      // Open in webview
      return false;
    }

    // If not http urls, open in external app/browser
    return _openExternalUrl(url);
  }

  Future<bool> _openExternalUrl(String url) async {
    // Try to open other sites in external browser/app, not `platformDefault` or
    // `inAppBrowserView` because it does not work properly on iOS. When user
    // opens an external link and then closes it before the page is loaded, it
    // tries to open this link in webview again, which is not expected.
    try {
      final newUrl = Tools.prepareURL(url);
      return await Tools.launchURL(
        newUrl,
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (err, stack) {
      printError(err, stack);
      return false;
    }
  }
}
