import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart';

import '../connectivity_service.dart';

class NetworkConnectionStateWidget extends StatefulWidget {
  const NetworkConnectionStateWidget({super.key, required this.builder});

  final Widget Function(bool isConnection) builder;

  @override
  State<NetworkConnectionStateWidget> createState() =>
      _NetworkConnectionStateWidgetState();
}

class _NetworkConnectionStateWidgetState
    extends State<NetworkConnectionStateWidget> with LifecycleMixin {
  final _pauseAppController = ValueNotifier<bool>(false);

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
    return StreamBuilder(
      stream: ConnectivityService.instance.connectionStream,
      builder: (context, asyncSnapshot) {
        return widget.builder(
            asyncSnapshot.data ?? ConnectivityService.instance.isConnect);
      },
    );
  }
}
