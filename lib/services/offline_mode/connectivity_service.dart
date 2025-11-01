import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for managing and checking internet connection status
/// Provides methods to check connectivity, monitor connection changes
/// and perform network-aware tasks
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  static ConnectivityService get instance => _instance;

  // Cache connection status to avoid frequent checks
  bool? _lastConnectionStatus;
  DateTime? _lastCheckTime;
  static const Duration _cacheTimeout = Duration(seconds: 5);

  bool get isConnect => _lastConnectionStatus ?? true;

  // Stream controller for monitoring connection changes
  StreamController<bool>? _connectionController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _timer;

  void init() {
    _maybeInitStream();
    _checkConnection();
  }

  void _checkConnection() {
    _timer = Timer.periodic(_cacheTimeout, (_) async {
      final isConnect = await isConnected();
      _connectionController?.add(isConnect);
    });
  }

  /// Check basic network connectivity (only checks connectivity, no ping)
  Future<bool> isConnected({bool forceCheck = false}) async {
    try {
      // Use cache if still valid
      if (_lastConnectionStatus != null &&
          _lastCheckTime != null &&
          DateTime.now().difference(_lastCheckTime!) < _cacheTimeout &&
          forceCheck == false) {
        return _lastConnectionStatus!;
      }

      // final connectivityResults = await _connectivity.checkConnectivity();
      // final isConnected =
      //     !connectivityResults.contains(ConnectivityResult.none);

      final hasInternet = await hasInternetAccess();

      // Update cache
      _lastConnectionStatus = hasInternet;
      _lastCheckTime = DateTime.now();

      return _lastConnectionStatus!;
    } catch (e) {
      if (kDebugMode) {
        print('ConnectivityService.isConnected error: $e');
      }
      return false;
    }
  }

  /// Check if internet is actually accessible (performs ping test)
  Future<bool> hasInternetAccess({
    String testHost = 'google.com',
    int port = 443,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      // Perform ping test
      final socket = await Socket.connect(
        testHost,
        port,
        timeout: timeout,
      );
      socket.destroy();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ConnectivityService.hasInternetAccess error: $e');
      }
      return false;
    }
  }

  /// Get current connection types
  Future<List<ConnectivityResult>> getConnectionTypes() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      if (kDebugMode) {
        print('ConnectivityService.getConnectionTypes error: $e');
      }
      return [ConnectivityResult.none];
    }
  }

  /// Get connection type description as string
  Future<String> getConnectionDescription() async {
    final types = await getConnectionTypes();
    if (types.contains(ConnectivityResult.none)) {
      return 'No connection';
    }

    final descriptions = types.map((type) {
      switch (type) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile data';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.other:
          return 'Other';
        case ConnectivityResult.none:
          return 'No connection';
      }
    }).toList();

    return descriptions.join(', ');
  }

  /// Stream to monitor connection status changes
  Stream<bool> get connectionStream {
    _maybeInitStream();

    return _connectionController!.stream;
  }

  void _maybeInitStream() {
    _connectionController ??= StreamController<bool>.broadcast();

    // Initialize subscription if not already done
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final connected = await isConnected();
        _connectionController?.add(connected);
      },
    );
  }

  /// Add listener for connection changes
  StreamSubscription<bool> addConnectionListener(
    void Function(bool isConnected) onConnectionChanged,
  ) {
    return connectionStream.listen(onConnectionChanged);
  }

  /// Wait until internet connection is available
  Future<void> waitForConnection({
    Duration timeout = const Duration(minutes: 1),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;
    Timer? checkTimer;

    // Set timeout
    timeoutTimer = Timer(timeout, () {
      checkTimer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException(
          'Timeout waiting for internet connection',
          timeout,
        ));
      }
    });

    // Check periodically
    void checkConnection() async {
      try {
        if (await hasInternetAccess()) {
          timeoutTimer?.cancel();
          checkTimer?.cancel();
          if (!completer.isCompleted) {
            completer.complete();
          }
        } else {
          checkTimer = Timer(checkInterval, checkConnection);
        }
      } catch (e) {
        checkTimer = Timer(checkInterval, checkConnection);
      }
    }

    // Start checking
    checkConnection();

    return completer.future;
  }

  /// Execute function when internet connection is available
  Future<T> executeWhenConnected<T>(
    Future<T> Function() action, {
    Duration timeout = const Duration(minutes: 1),
    int maxRetries = 3,
  }) async {
    var retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Wait for connection if needed
        if (!await hasInternetAccess()) {
          await waitForConnection(timeout: timeout);
        }

        // Execute action
        return await action();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }

        // Wait a bit before retry
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }

    throw Exception('Failed to execute action after $maxRetries retries');
  }

  /// Check whether API call should be made
  /// Returns true if connected, false if not
  Future<bool> shouldMakeApiCall() async {
    return await hasInternetAccess();
  }

  /// Wrapper for API calls with retry logic
  Future<T> makeApiCallWithRetry<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool requireInternetAccess = true,
  }) async {
    var retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        // Check connection if required
        if (requireInternetAccess && !await hasInternetAccess()) {
          throw Exception('No internet connection available');
        }

        return await apiCall();
      } catch (e) {
        retryCount++;

        if (retryCount > maxRetries) {
          rethrow;
        }

        if (kDebugMode) {
          print('API call failed (attempt $retryCount/$maxRetries): $e');
        }

        // Wait before retry
        await Future.delayed(retryDelay * retryCount);
      }
    }

    throw Exception('API call failed after $maxRetries retries');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController?.close();
    _connectivitySubscription = null;
    _connectionController = null;
    _timer?.cancel();
    _timer = null;
  }
}
