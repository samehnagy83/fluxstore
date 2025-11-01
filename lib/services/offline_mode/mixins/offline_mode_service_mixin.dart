import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';

import '../../../common/config.dart';
import '../../../common/tools/flash.dart';
import '../connectivity_service.dart';
import '../widgets/global_offline_banner.dart';
import '../widgets/network_connection_state_widget.dart';

/// Because some errors are displayed using Flash, the network banner gets
/// covered when shown. Therefore, the network banner needs to be hidden when
/// a Flash internet error is displayed.
final _offlineBannerController = OfflineBannerController();
mixin OfflineModeServiceMixin {
  bool get _isEnable => kOfflineModeConfig.enable;

  void initConnectivityService() {
    if (_isEnable) {
      ConnectivityService.instance.init();
    }
  }

  void disposeConnectivityService() {
    if (_isEnable) {
      ConnectivityService.instance.dispose();
    }
  }

  Widget manageInternetConnection(Widget child) => _isEnable
      ? GlobalOfflineBanner(controller: _offlineBannerController, child: child)
      : child;

  Widget renderWidgetWithNetworkConnectState(
          Widget Function(bool isConnection) builder) =>
      _isEnable
          ? NetworkConnectionStateWidget(builder: builder)
          : builder(true);

  Future<bool> checkInternet(BuildContext context,
      {bool showErrorMessage = true, bool forceCheck = false}) async {
    if (_isEnable == false) {
      return true;
    }

    if (await ConnectivityService().isConnected(forceCheck: forceCheck) ==
        false) {
      if (showErrorMessage) {
        _offlineBannerController.toggle?.call(false);

        unawaited(FlashHelper.errorMessage(
          context,
          message: S.of(context).noInternetConnection,
        )?.then(
          (value) {
            _offlineBannerController.toggle?.call(true);
          },
        ));
      }
      return false;
    }

    return true;
  }
}
