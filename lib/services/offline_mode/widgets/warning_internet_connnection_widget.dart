import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';

import '../../../common/config.dart';
import '../connectivity_service.dart';

class WarningInternetConnnectionWidget extends StatefulWidget {
  const WarningInternetConnnectionWidget({super.key, this.onChangeState});

  final void Function(bool isConnected)? onChangeState;

  @override
  State<WarningInternetConnnectionWidget> createState() =>
      _WarningInternetConnnectionWidgetState();
}

class _WarningInternetConnnectionWidgetState
    extends State<WarningInternetConnnectionWidget> with LifecycleMixin {
  final _pauseAppController = ValueNotifier<bool>(false);

  void _updateConnectState(isConnected) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChangeState?.call(isConnected);
    });
  }

  @override
  void onChangeLifecycleState(AppLifecycleState lifecycleState) async {
    if (_pauseAppController.value && LifecycleEventHandler.isPaused == false) {
      await ConnectivityService.instance.isConnected(forceCheck: true);
    }

    _pauseAppController.value = LifecycleEventHandler.isPaused;
  }

  @override
  void dispose() {
    _pauseAppController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kOfflineModeConfig.enable == false) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
        stream: ConnectivityService.instance.connectionStream,
        builder: (context, asyncSnapshot) {
          final isConnected =
              asyncSnapshot.data ?? ConnectivityService.instance.isConnect;

          _updateConnectState(isConnected);

          if (isConnected || _pauseAppController.value) {
            return const SizedBox();
          }

          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.sizeOf(context).width,
              color: const Color.fromARGB(255, 237, 145, 140),
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 16,
              ),
              child: Text(
                S.of(context).noInternetReconnectToContinue,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        });
  }
}
