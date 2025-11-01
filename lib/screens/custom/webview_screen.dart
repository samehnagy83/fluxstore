import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/extensions/extensions.dart';
import '../../models/user_model.dart';
import '../../widgets/common/index.dart';
import '../../widgets/common/webview/webview_interface.dart';
import '../../widgets/web_layout/appbar_web_control_delegate.dart';

class WebViewScreen extends StatefulWidget {
  final String? title;
  final String? url;
  final String script;
  final bool enableForward;
  final bool enableBackward;
  final bool enableClose;

  /// is determine if include cookie/session into WebView URL
  final bool auth;

  const WebViewScreen({
    this.title,
    this.auth = false,
    this.script = '',
    this.enableForward = true,
    this.enableBackward = true,
    this.enableClose = true,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _StateWebViewScreen();
}

class _StateWebViewScreen extends State<WebViewScreen> {
  final WebViewDelegateController _webViewDelegateController =
      WebViewDelegateController();

  void _setOnBackWebControlDelegate() {
    AppBarWebControlDelegate.onBack = () {
      return _webViewDelegateController.onBack?.call() ?? Future.value(false);
    };
  }

  @override
  void initState() {
    super.initState();

    _setOnBackWebControlDelegate();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('webview-screen-${widget.url}-$hashCode'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0) {
          _setOnBackWebControlDelegate();
        }
      },
      child: Selector<UserModel, String?>(
        selector: (context, model) => model.user?.cookie,
        shouldRebuild: (prev, next) => prev != next,
        builder: (_, cookie, __) {
          var url = widget.url ?? '';

          /// Loading if the Auth cookie is active but URL not changed
          if (url.isEmpty || (widget.auth && cookie == null)) {
            return Center(child: kLoadingWidget(context));
          }

          url = url.addWooCookieToUrl(cookie);
          final enableClose = Navigator.canPop(context) && widget.enableClose;
          final showAppBar = widget.enableBackward ||
              widget.enableBackward ||
              enableClose ||
              (widget.title?.isNotEmpty ?? false);

          return SafeArea(
            child: WebView(
              url,
              key: Key('webview-$url-$cookie-$hashCode'),
              title: widget.title,
              enableForward: widget.enableForward,
              enableBackward: widget.enableBackward,
              enableClose: enableClose,
              script: widget.script.isEmptyOrNull
                  ? kWebViewConfig.webViewScript
                  : widget.script,
              routeName: RouteList.page,
              showAppBar: showAppBar,
              webViewDelegateController: _webViewDelegateController,
              onPageFinished: AppBarWebControlDelegate.emitRoute,
            ),
          );
        },
      ),
    );
  }
}
