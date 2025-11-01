import 'package:flutter/material.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/extensions/extensions.dart';
import '../../../screens/common/app_bar_mixin.dart';

class WebViewDelegateController {
  Future<bool> Function()? onBack;
}

abstract class WebviewInterface extends StatefulWidget {
  final String? url;
  final String? data; // html code
  final String? title;
  final AppBar? appBar;
  final bool enableForward;
  final bool enableBackward;
  final bool enableClose;
  final Future<bool> Function(String url)? shouldPreventNavigator;
  final void Function(
    String?,
    Future<void> Function(String url)? redirectLink,
    Future<String?> Function()? getHtml,
  )? onRedirectUrl;
  final Function(String url)? onPageFinished;
  final Function? onClosed;
  final String script;
  final Map<String, String>? headers;
  final String? routeName;
  final bool hideNewAppBar;
  final bool showAppBar;
  final bool showLoading;
  final WebViewDelegateController? webViewDelegateController;

  const WebviewInterface({
    super.key,
    this.title,
    this.url,
    this.data,
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
    this.onRedirectUrl,
    this.webViewDelegateController,
  }) : assert(
          !(!showAppBar && (enableForward || enableBackward || enableClose)),
          'Cannot hide app bar if one of the following options EnableForward or EnableBackward or EnableClose is enabled',
        );
}

abstract class StateWebviewInterface<T extends WebviewInterface>
    extends State<T> with AppBarMixin {
  String? get url {
    var value = widget.url;
    final uri = value?.toUri();
    if (uri != null && uri.scheme.isEmpty) {
      value = 'https://$value';
    }
    if (kWebViewConfig.alwaysClearWebViewCache) {
      value = value?.addUrlQuery(
        'dummy=${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    return value;
  }

  bool get canPop =>
      ModalRoute.of(context)?.canPop ?? Navigator.of(context).canPop();

  Future<bool> onTapBackButton(BuildContext buildContext);

  Future<bool> onTapForwardButton(BuildContext buildContext);

  void onTapCloseButton();

  Widget renderWebview();

  AppBar _renderDefaultAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0.0,
      centerTitle: true,
      title: Text(
        widget.title ?? '',
        style: Theme.of(context)
            .textTheme
            .titleLarge!
            .copyWith(fontWeight: FontWeight.w600),
      ),
      leadingWidth: 100,
      actions: [
        if (widget.enableClose && canPop) ...[
          IconButton(
            onPressed: onTapCloseButton,
            icon: const Icon(Icons.close, size: 20),
          ),
          const SizedBox(width: 10),
        ],
      ],
      leading: Builder(
        builder: (buildContext) {
          return Row(
            children: [
              if (widget.enableBackward)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () => onTapBackButton(buildContext),
                ),
              if (widget.enableForward)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: () => onTapForwardButton(buildContext),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.webViewDelegateController?.onBack = () => onTapBackButton(context);
  }

  @override
  Widget build(BuildContext context) {
    final routeName = widget.routeName;

    return renderScaffold(
      routeName: (routeName != null && routeName.isNotEmpty)
          ? routeName
          : RouteList.webview,
      hideNewAppBar: widget.hideNewAppBar,
      secondAppBar:
          widget.showAppBar ? (widget.appBar ?? _renderDefaultAppBar()) : null,
      child: renderWebview(),
    );
  }
}
