import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../common/config.dart';
import 'webview_interface.dart';

/// using [InAppWebView] to load webview for web platform.
/// [InAppWebView] use iframe to load content in a webview.
/// goBack(),goForward() only works if iframe's window is same-origin with its parent

class WebviewWeb extends WebviewInterface {
  const WebviewWeb({
    super.key,
    super.title,
    super.url,
    super.data,
    super.appBar,
    super.onClosed,
    super.enableForward,
    super.enableBackward,
    super.enableClose,
    super.routeName,
    super.hideNewAppBar,
    super.showAppBar,
    super.showLoading,
    super.webViewDelegateController,
  });

  @override
  StateWebviewWeb createState() => StateWebviewWeb();
}

class StateWebviewWeb extends StateWebviewInterface<WebviewWeb> {
  int selectedIndex = 1;

  InAppWebViewController? webViewController;

  URLRequest? get initialUrlRequest {
    final webUrl = url;
    if (webUrl != null) {
      return URLRequest(
        url: WebUri(webUrl),
        headers: widget.headers,
      );
    }
    return null;
  }

  InAppWebViewInitialData? get initialData {
    final html = widget.data;
    if (html != null && html.isNotEmpty) {
      return InAppWebViewInitialData(
        data: html,
      );
    }
    return null;
  }

  @override
  Future<bool> onTapBackButton(BuildContext buildContext) async {
    final canGoBack = await webViewController?.canGoBack();
    if (canGoBack == true) {
      await webViewController?.goBack();
      return true;
    }

    if (canPop) {
      widget.onClosed?.call();
      Navigator.of(context).pop();
      return true;
    }

    return false;
  }

  @override
  void onTapCloseButton() {
    widget.onClosed?.call();

    if (canPop) {
      Navigator.of(context).pop();
    }
  }

  @override
  Future<bool> onTapForwardButton(BuildContext buildContext) async {
    final canGoForward = await webViewController?.canGoForward();
    if (canGoForward == true) {
      await webViewController?.goForward();
      return true;
    }

    return false;
  }

  @override
  Widget renderWebview() {
    return IndexedStack(
      index: selectedIndex,
      children: [
        InAppWebView(
          initialUrlRequest: initialUrlRequest,
          initialData: initialData,
          onWebViewCreated: (controller) {
            webViewController = controller;
            setState(() => selectedIndex = 0);
          },
        ),
        if (widget.showLoading)
          Center(
            child: kLoadingWidget(context),
          )
        else
          const SizedBox(),
      ],
    );
  }
}
