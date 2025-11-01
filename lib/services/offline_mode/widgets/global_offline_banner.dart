import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';

import '../../../common/config.dart';
import '../connectivity_service.dart';

/// Global offline banner that shows across all screens without modifying individual screen code
/// This widget uses overlay to display a persistent banner when offline
class GlobalOfflineBanner extends StatefulWidget {
  const GlobalOfflineBanner({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;

  final OfflineBannerController? controller;

  @override
  State<GlobalOfflineBanner> createState() => _GlobalOfflineBannerState();
}

class _GlobalOfflineBannerState extends State<GlobalOfflineBanner>
    with LifecycleMixin {
  final _pauseAppController = ValueNotifier<bool>(false);
  bool _isOfflineBannerVisible = false;
  bool _isManualHide = false;
  OfflineBannerController? get controller => widget.controller;

  @override
  void onChangeLifecycleState(AppLifecycleState lifecycleState) async {
    if (_pauseAppController.value && LifecycleEventHandler.isPaused == false) {
      await ConnectivityService.instance.isConnected(forceCheck: true);
    }

    _pauseAppController.value = LifecycleEventHandler.isPaused;
  }

  @override
  void initState() {
    super.initState();
    controller?.toggle = (isShow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (isShow) {
            _isManualHide = false;
            _isOfflineBannerVisible = ConnectivityService.instance.isConnect;
          } else {
            _isManualHide = true;
            _isOfflineBannerVisible = false;
          }
        });
      });
    };
  }

  @override
  void dispose() {
    _pauseAppController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return child directly if offline mode is disabled
    if (kOfflineModeConfig.enable == false) {
      return widget.child;
    }

    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.connectionStream,
      builder: (context, asyncSnapshot) {
        final isConnected =
            asyncSnapshot.data ?? ConnectivityService.instance.isConnect;

        // Update banner visibility state
        _isOfflineBannerVisible = _isManualHide
            ? _isOfflineBannerVisible
            : (!isConnected && !_pauseAppController.value);

        return Stack(
          children: [
            // Main app content
            widget.child,
            // Offline banner overlay
            if (_isOfflineBannerVisible) _buildOfflineBanner(context),
          ],
        );
      },
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Material(
          elevation: 4,
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            color:
                const Color.fromARGB(255, 237, 145, 140).withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    S.of(context).noInternetReconnectToContinue,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OfflineBannerController {
  void Function(bool isShow)? toggle;
}
