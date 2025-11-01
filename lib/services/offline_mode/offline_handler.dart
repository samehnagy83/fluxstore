import 'dart:async';
import 'dart:convert' show utf8, jsonEncode;

import 'package:crypto/crypto.dart' as crypto;
import 'package:inspireui/utils/logs.dart';

import '../../common/config.dart';
import '../../data/boxes.dart';
import 'connectivity_service.dart';

class OfflineHandler {
  static final OfflineHandler _instance = OfflineHandler._internal();
  factory OfflineHandler() => _instance;
  OfflineHandler._internal();

  final ConnectivityService _networkAwareApiService = ConnectivityService();
  final OfflineCacheBox _offlineCacheBox = OfflineCacheBox();
  String _keyCache = '';

  void setKeyCache(String keyCache) {
    _keyCache = keyCache;
  }

  bool get isSetKeyCache => _keyCache.isEmpty;

  bool get _isDebugMode => false;

  String hashString(
    String keyHash, {
    List? keys,
  }) {
    final listStringKey = keys
            ?.map((e) {
              if (e is Map || e is List) {
                return jsonEncode(e);
              }

              return e.toString();
            })
            .toList()
            .join('-') ??
        '';

    return crypto.md5
        .convert(utf8.encode('$_keyCache$keyHash$listStringKey'))
        .toString();
  }

  /// Check basic network connectivity (only checks connectivity, no ping)
  Future<bool> isConnected() async {
    return await _networkAwareApiService.isConnected();
  }

  /// Cache API response data using Hive box
  Future<void> _cacheData(String endPoint, dynamic data) async {
    try {
      await _offlineCacheBox.setApiCache(endPoint, data);
    } catch (e, trace) {
      // Log error but don't throw to avoid breaking the API call
      if (_isDebugMode) {
        printLog('Failed to cache data for endpoint $endPoint: $e $trace');
      }
    }
  }

  /// Get cached API response data from Hive box
  Future<dynamic> _getCachedData(String key) async {
    try {
      final data = _offlineCacheBox.getApiCache(key);

      return data;
    } catch (e, trace) {
      // Log error and return null if cache retrieval fails
      if (_isDebugMode) {
        printLog('Failed to get cached data for key $key: $e $trace');
      }
      return null;
    }
  }

  /// Check if cache exists and is valid for an key
  Future<bool> hasCachedData(String key) async {
    try {
      return _offlineCacheBox.hasValidApiCache(key);
    } catch (e) {
      if (_isDebugMode) {
        printLog('Failed to check cache for key $key: $e');
      }
      return false;
    }
  }

  /// Clear all API cache
  Future<void> clearAllCache() async {
    try {
      await _offlineCacheBox.clearApiCache();
      if (_isDebugMode) {
        printLog('API cache cleared successfully');
      }
    } catch (e, trace) {
      if (_isDebugMode) {
        printLog('Failed to clear API cache: $e $trace');
      }
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      await _offlineCacheBox.clearExpiredApiCache();
      if (_isDebugMode) {
        printLog('Expired API cache cleared successfully');
      }
    } catch (e, trace) {
      if (_isDebugMode) {
        printLog('Failed to clear expired API cache: $e $trace');
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    try {
      return _offlineCacheBox.getApiCacheStats();
    } catch (e) {
      if (_isDebugMode) {
        printLog('Failed to get cache stats: $e');
      }
      return {
        'totalEntries': 0,
        'expiredEntries': 0,
        'validEntries': 0,
        'cacheExpiration': 1,
      };
    }
  }

  Future<T> callApi<T>(Future<T> Function() funcApi, String keyHash,
      {bool useCache = true}) async {
    final isConnect = await isConnected();

    if (!isConnect && kOfflineModeConfig.enable && useCache) {
      if (_isDebugMode) {
        printLog('No internet connection, checking cache for: $keyHash');
      }

      final cachedData = await _getCachedData(keyHash);
      if (cachedData != null) {
        if (_isDebugMode) {
          printLog('Returning cached data for: $keyHash');
        }
        return cachedData;
      }

      if (_isDebugMode) {
        printLog('No cached data available for: $keyHash');
      }
      throw Exception(
          'No internet connection available and no cached data found');
    }

    try {
      if (_isDebugMode) {
        printLog('Making API call to: $keyHash');
      }

      final result = await funcApi();

      if (kOfflineModeConfig.enable) {
        // Cache the result asynchronously without waiting
        unawaited(_cacheData(keyHash, result));

        if (_isDebugMode) {
          printLog('API call successful for: $keyHash');
        }
      }

      return result;
    } catch (e, trace) {
      if (_isDebugMode) {
        printLog('API call failed for: $keyHash, error: $e $trace');
      }

      if (kOfflineModeConfig.enable && isConnect == false) {
        // Try to return cached data as fallback
        final cachedData = await _getCachedData(keyHash);
        if (cachedData != null) {
          if (_isDebugMode) {
            printLog('Returning cached data as fallback for: $keyHash');
          }
          return cachedData;
        }
      }

      // No cache available, rethrow the original error
      rethrow;
    }
  }
}
