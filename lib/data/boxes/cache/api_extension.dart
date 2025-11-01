part of '../../boxes.dart';

/// Extension for caching API responses
extension ApiCacheExtension on OfflineCacheBox {
  static const String _apiCachePrefix = 'api_cache_';
  static const String _apiTimestampPrefix = 'api_timestamp_';
  static const Duration _defaultCacheExpiration = Duration(hours: 100);

  /// Get cached API response data
  dynamic getApiCache(String endpoint) {
    final cacheKey = '$_apiCachePrefix$endpoint';
    final timestampKey = '$_apiTimestampPrefix$endpoint';
    printLog('[ApiCacheExtension] API get cached for $cacheKey');

    // Check if cache exists
    final cachedData = box.get(cacheKey);
    if (cachedData == null) {
      printLog('[ApiCacheExtension] [NULL] API get cached for $cacheKey');
      return null;
    }

    // Check if cache is expired
    final timestamp = box.get(timestampKey);
    printLog(
        '[ApiCacheExtension] [cachedData] API get cached for $cacheKey - $cachedData');
    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      if (now.difference(cacheTime) > _defaultCacheExpiration) {
        // Cache expired, remove it
        box.delete(cacheKey);
        box.delete(timestampKey);
        printLog(
            '[ApiCacheExtension] [Cache expired] API get cached for $cacheKey');
        return null;
      }
    }
    if (cachedData is QueryResult) {
      return cachedData;
    } else if (cachedData is Map) {
      // Check if this is a cached HTTP Response
      if (cachedData['_type'] == 'http_response') {
        // Reconstruct HTTP Response from cached data
        final response = http.Response(
          cachedData['body'] ?? '',
          cachedData['statusCode'] ?? 200,
          headers: Map<String, String>.from(cachedData['headers'] ?? {}),
          reasonPhrase: cachedData['reasonPhrase'],
        );
        printLog(
            '[ApiCacheExtension] [Success] HTTP Response restored from cache for $cacheKey');
        return response;
      }

      printLog('[ApiCacheExtension] [Success] API get cached for $cacheKey');
      printLog(cachedData);
      return cachedData;
    }

    // Try to parse if it's a string (JSON)
    if (cachedData is String) {
      try {
        final parsed = jsonDecode(cachedData);
        printLog('[ApiCacheExtension] [Success] API get cached for $cacheKey');

        return parsed;
      } catch (e) {
        // Invalid JSON, remove cache
        box.delete(cacheKey);
        box.delete(timestampKey);
        printLog(
            '[ApiCacheExtension] [Error] API get cached for $cacheKey \n $e');
        return cachedData;
      }
    }

    return null;
  }

  /// Set cached API response data
  Future<void> setApiCache(String endpoint, dynamic data,
      {bool isRemoveCache = false}) async {
    final cacheKey = '$_apiCachePrefix$endpoint';
    final timestampKey = '$_apiTimestampPrefix$endpoint';

    if (data == null) {
      if (isRemoveCache) {
        // Remove cache if data is null
        await box.delete(cacheKey);
        await box.delete(timestampKey);
        return;
      }

      return;
    }

    try {
      dynamic cacheableData;
      if (data is QueryResult) {
        cacheableData = data;
      } else if (data is http.Response) {
        // Convert Response to cacheable format
        cacheableData = {
          '_type': 'http_response',
          'body': data.body,
          'statusCode': data.statusCode,
          'headers': data.headers,
          'reasonPhrase': data.reasonPhrase,
        };
      } else if (data is Map) {
        cacheableData = data;
      } else {
        // Try to convert to JSON string for other types
        cacheableData = jsonEncode(data);
      }

      await box.put(cacheKey, cacheableData);
      // Store timestamp
      await box.put(timestampKey, DateTime.now().millisecondsSinceEpoch);
      printLog(
          '[ApiCacheExtension] API data cached for $cacheKey [${cacheableData != null} ]');
    } catch (e) {
      // If encoding fails, don't cache
      printLog(
          '[ApiCacheExtension] Failed to cache API data for $endpoint: $e');
    }
  }

  /// Check if cache exists and is valid for an endpoint
  bool hasValidApiCache(String endpoint) {
    final cacheKey = '$_apiCachePrefix$endpoint';
    final timestampKey = '$_apiTimestampPrefix$endpoint';

    // Check if cache exists
    if (!box.containsKey(cacheKey)) {
      return false;
    }

    // Check if cache is expired
    final timestamp = box.get(timestampKey);
    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      return now.difference(cacheTime) <= _defaultCacheExpiration;
    }

    return false;
  }

  /// Clear all API cache
  Future<void> clearApiCache() async {
    final keysToDelete = <String>[];

    // Find all cache keys
    for (final key in box.keys) {
      if (key is String &&
          (key.startsWith(_apiCachePrefix) ||
              key.startsWith(_apiTimestampPrefix))) {
        keysToDelete.add(key);
      }
    }

    // Delete all found keys
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Clear expired API cache
  Future<void> clearExpiredApiCache() async {
    final keysToDelete = <String>[];
    final now = DateTime.now();

    // Find all timestamp keys
    for (final key in box.keys) {
      if (key is String && key.startsWith(_apiTimestampPrefix)) {
        final timestamp = box.get(key);
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (now.difference(cacheTime) > _defaultCacheExpiration) {
            // Cache expired
            final endpoint = key.substring(_apiTimestampPrefix.length);
            keysToDelete.add('$_apiCachePrefix$endpoint');
            keysToDelete.add(key);
          }
        }
      }
    }

    // Delete all expired keys
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getApiCacheStats() {
    var totalCacheEntries = 0;
    var expiredEntries = 0;
    final now = DateTime.now();

    for (final key in box.keys) {
      if (key is String && key.startsWith(_apiTimestampPrefix)) {
        totalCacheEntries++;
        final timestamp = box.get(key);
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (now.difference(cacheTime) > _defaultCacheExpiration) {
            expiredEntries++;
          }
        }
      }
    }

    return {
      'totalEntries': totalCacheEntries,
      'expiredEntries': expiredEntries,
      'validEntries': totalCacheEntries - expiredEntries,
      'cacheExpiration': _defaultCacheExpiration.inHours,
    };
  }
}
