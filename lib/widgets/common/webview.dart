import 'package:flutter/material.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import 'webview/webview.dart';
import 'webview/webview_interface.dart';

class WebView extends StatelessWidget with WebviewMixin {
  late final String data;
  late final bool isHTML;
  final String? title;
  final AppBar? appBar;
  final bool enableForward;
  final bool enableBackward;
  final bool enableClose;
  final Future<bool> Function(String url)? shouldPreventNavigator;
  final Function(String url)? onPageFinished;
  final Function? onClosed;
  final String script;
  final Map<String, String>? headers;
  final String? routeName;
  final bool hideNewAppBar;
  final bool showAppBar;
  final bool showLoading;
  final WebViewDelegateController? webViewDelegateController;

  WebView(
    String url, {
    super.key,
    this.title,
    this.appBar,
    this.shouldPreventNavigator,
    this.onPageFinished,
    this.onClosed,
    this.script = '',
    this.headers,
    this.enableForward = true,
    this.enableBackward = true,
    this.enableClose = true,
    this.routeName,
    this.hideNewAppBar = false,
    this.showAppBar = true,
    this.showLoading = true,
    this.webViewDelegateController,
  }) {
    data = url;
    isHTML = false;
  }

  WebView.html(
    String html, {
    super.key,
    this.title,
    this.appBar,
    this.shouldPreventNavigator,
    this.onPageFinished,
    this.onClosed,
    this.script = '',
    this.headers,
    this.enableForward = true,
    this.enableBackward = true,
    this.enableClose = true,
    this.routeName,
    this.hideNewAppBar = false,
    this.showAppBar = true,
    this.showLoading = true,
    this.webViewDelegateController,
  }) {
    data = html;
    isHTML = true;
  }

  String? get url => isHTML ? null : data;

  String? get html => isHTML ? data : null;

  @override
  Widget build(BuildContext context) {
    printLog('[WebView open]: $data');

    if (kIsWeb) {
      return WebviewWeb(
        url: url,
        data: html,
        title: title,
        routeName: routeName,
        enableForward: enableForward,
        enableBackward: enableBackward,
        enableClose: enableClose,
        onClosed: onClosed,
        appBar: appBar,
        showLoading: showLoading,
        showAppBar: showAppBar,
        hideNewAppBar: hideNewAppBar,
        webViewDelegateController: webViewDelegateController,
      );
    }

    if (isWindow || isMacOS) {
      return WebViewDesktop(
        url: url,
        data: html,
        title: title,
        script: script.isEmptyOrNull ? kWebViewConfig.webViewScript : script,
        headers: headers,
        enableForward: enableForward,
        enableBackward: enableBackward,
        enableClose: enableClose,
        onClosed: onClosed,
        appBar: appBar,
        showLoading: showLoading,
        showAppBar: showAppBar,
        hideNewAppBar: hideNewAppBar,
        webViewDelegateController: webViewDelegateController,
      );
    }

    if (kWebViewConfig.isInAppWebView) {
      return WebViewInApp(
        url: url,
        data: html,
        shouldPreventNavigator:
            shouldPreventNavigator ?? shouldPreventWebNavigation,
        routeName: routeName,
        title: title,
        script: script.isEmptyOrNull ? kWebViewConfig.webViewScript : script,
        headers: headers,
        enableForward: enableForward,
        enableBackward: enableBackward,
        enableClose: enableClose,
        onClosed: onClosed,
        onUrlChanged: (String? url, String? html, webViewController) {
          onPageFinished?.call(url ?? '');
        },
        appBar: appBar,
        showLoading: showLoading,
        showAppBar: showAppBar,
        hideNewAppBar: hideNewAppBar,
        webViewDelegateController: webViewDelegateController,
      );
    }

    return WebviewFlutter(
      url: url,
      data: html,
      title: title,
      shouldPreventNavigator:
          shouldPreventNavigator ?? shouldPreventWebNavigation,
      routeName: routeName,
      script: script.isEmptyOrNull ? kWebViewConfig.webViewScript : script,
      headers: headers,
      enableForward: enableForward,
      enableBackward: enableBackward,
      enableClose: enableClose,
      onClosed: onClosed,
      appBar: appBar,
      showLoading: showLoading,
      showAppBar: showAppBar,
      hideNewAppBar: hideNewAppBar,
      onPageFinished: onPageFinished,
      webViewDelegateController: webViewDelegateController,
    );
  }
}
