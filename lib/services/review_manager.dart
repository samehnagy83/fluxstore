import 'dart:async';

import 'package:flux_ui/flux_ui.dart';

import '../common/config.dart';
import '../common/config/models/review/review_config.dart';
import '../common/config/models/review/review_service_type.dart';
import '../common/config/review_config_validator.dart';
import '../common/constants.dart';
import '../dependency_injection/di_core.dart';
import '../frameworks/woocommerce/services/woo_commerce.dart';
import '../frameworks/woocommerce/services/woo_review_service.dart';
import '../models/entities/paging_response.dart';
import '../models/entities/rating_count.dart';
import '../models/entities/review.dart';
import '../models/entities/review_payload.dart';
import '../services/service_config.dart';
import '../services/services.dart';
import 'review_service.dart';

/// Unified manager for review configuration and service access
/// Provides encapsulated access to both ReviewConfig and ReviewService
/// with automatic site-aware configuration resolution
class ReviewManager {
  static ReviewManager get instance => injector.get<ReviewManager>();

  ReviewService? _cachedService;
  MultiSiteConfig? _currentSite;
  StreamSubscription? _eventSubscription;

  // Performance optimization: Cache validation results
  String? _lastValidatedSiteConfigHash;
  bool? _lastValidationResult;

  // Performance monitoring
  int _serviceCacheHits = 0;
  int _serviceCacheMisses = 0;

  ReviewManager() {
    _initializeEventListeners();
  }

  // ==================== Public API - Configuration Access ====================

  /// Get the current review configuration for the active site
  ReviewConfig get config {
    if (_currentSite?.configurations?['reviewConfig'] != null) {
      return _getSiteSpecificConfig(_currentSite!);
    }

    return _getGlobalConfig();
  }

  /// Maximum number of images allowed in reviews
  int get maxImage => config.maxImage;

  /// Whether review images are enabled
  bool get enableReviewImage => config.enableReviewImage;

  /// Whether reviews are enabled
  bool get enableReview => config.enableReview;

  /// Whether Judge.me service is configured
  bool get hasJudgeConfig => config.service == ReviewServiceType.judge;

  /// Judge.me shop domain
  String get judgeDomain => config.judgeConfig.domain;

  /// Judge.me API key (with security validation)
  String get judgeApiKey {
    final apiKey = config.judgeConfig.apiKey;
    if (apiKey.isEmpty) {
      printLog('⚠️ Warning: Judge.me API key is empty');
    }
    // Security: Don't log the actual API key
    return apiKey;
  }

  // ==================== Public API - Service Access ====================

  /// Get the current review service for the active site
  ReviewService get service => _getServiceForCurrentSite();

  // ==================== Public API - Convenience Methods ====================

  /// Create a new review
  Future<void> createReview(ReviewPayload payload) =>
      service.createReview(payload);

  /// Get reviews for a product
  Future<PagingResponse<Review>> getReviews(
    String productId, {
    int page = 1,
    int perPage = 20,
  }) =>
      service.getReviews(productId, page: page, perPage: perPage);

  /// Get reviews by user email
  Future<PagingResponse<Review>> getListReviewByUserEmail(
    String email, {
    int page = 1,
    int perPage = 20,
    String? status,
  }) =>
      service.getListReviewByUserEmail(
        email,
        page: page,
        perPage: perPage,
        status: status,
      );

  /// Get product rating count
  Future<RatingCount?> getProductRatingCount(String productId) =>
      service.getProductRatingCount(productId);

  // ==================== Site Management ====================

  /// Update the current site configuration
  /// This will invalidate cached config and service
  void updateSite(MultiSiteConfig? siteConfig) {
    if (_currentSite != siteConfig) {
      final previousSite = _currentSite?.name;
      _currentSite = siteConfig;
      _invalidateCache();
      _logConfigurationChange(previousSite, siteConfig?.name);
    }
  }

  // ==================== Private Implementation ====================

  /// Get service for the current site with caching
  ReviewService _getServiceForCurrentSite() {
    if (_cachedService == null) {
      _serviceCacheMisses++;
      _cachedService = _createReviewService();
      _logServiceCreation(config.service, hasJudgeConfig ? judgeDomain : null);
    } else {
      _serviceCacheHits++;
    }
    return _cachedService!;
  }

  /// Get site-specific configuration with validation
  ReviewConfig _getSiteSpecificConfig(MultiSiteConfig siteConfig) {
    try {
      final siteReviewConfigMap =
          Map<String, dynamic>.from(siteConfig.configurations!['reviewConfig']);

      // Performance optimization: Cache validation results
      final configHash = _generateConfigHash(siteReviewConfigMap);
      if (_lastValidatedSiteConfigHash == configHash &&
          _lastValidationResult == true) {
        // Skip validation if we've already validated this exact config
        return ReviewConfig.fromJson(siteReviewConfigMap);
      }

      // Validate configuration
      final validation = ReviewConfigValidator.validate(siteReviewConfigMap);

      // Cache validation result
      _lastValidatedSiteConfigHash = configHash;
      _lastValidationResult = validation.isValid;

      if (!validation.isValid) {
        _logConfigErrors(siteConfig.name, validation.errors);
        return _getGlobalConfig();
      }

      if (validation.hasWarnings) {
        _logConfigWarnings(siteConfig.name, validation.warnings);
      }

      printLog('✅ Loaded site-specific review config for ${siteConfig.name}');
      return ReviewConfig.fromJson(siteReviewConfigMap);
    } catch (e) {
      printLog('❌ Error loading site-specific review config: $e');
      return _getGlobalConfig();
    }
  }

  /// Get global configuration as fallback
  ReviewConfig _getGlobalConfig() {
    return ReviewConfig.fromJson(
      Map<String, dynamic>.from(Configurations.reviewConfig ?? {}),
    );
  }

  /// Create review service based on current configuration
  ReviewService _createReviewService() {
    return ReviewService.create(
      reviewConfig: config,
      factoryReviewServiceNative: () => _createNativeService(),
    );
  }

  /// Create platform-specific native service
  ReviewService _createNativeService() {
    if (ServerConfig().isWooPluginSupported) {
      // For WooCommerce-based platforms, we need to access the WooCommerce API
      // through the Services API which provides the wcApi
      final services = Services();
      if (services.api is WooCommerceService) {
        final wooApi = services.api as WooCommerceService;
        return WooReviewService(wooApi.wcConnector);
      }
    }
    return const ReviewService.base();
  }

  /// Invalidate cached configuration and service
  void _invalidateCache() {
    _cachedService = null;
    // Also invalidate validation cache
    _lastValidatedSiteConfigHash = null;
    _lastValidationResult = null;
  }

  /// Generate hash for configuration to enable validation caching
  String _generateConfigHash(Map<String, dynamic> config) {
    // Simple hash based on config content
    final configString = config.toString();
    return configString.hashCode.toString();
  }

  // ==================== Performance Monitoring ====================

  /// Get cache performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final totalServiceAccess = _serviceCacheHits + _serviceCacheMisses;

    return {
      'serviceCacheHitRatio': totalServiceAccess > 0
          ? '${(_serviceCacheHits / totalServiceAccess * 100).toStringAsFixed(1)}%'
          : '0%',
      'serviceCacheHits': _serviceCacheHits,
      'serviceCacheMisses': _serviceCacheMisses,
      'totalServiceAccess': totalServiceAccess,
    };
  }

  /// Log performance metrics
  void logPerformanceMetrics() {
    final metrics = getPerformanceMetrics();
    printLog('📊 ReviewManager Performance Metrics:');
    printLog('  Config Cache Hit Ratio: ${metrics['configCacheHitRatio']}');
    printLog('  Service Cache Hit Ratio: ${metrics['serviceCacheHitRatio']}');
    printLog('  Total Config Access: ${metrics['totalConfigAccess']}');
    printLog('  Total Service Access: ${metrics['totalServiceAccess']}');
  }

  /// Initialize event listeners for configuration changes
  void _initializeEventListeners() {
    _eventSubscription = eventBus.on<EventReviewConfigChanged>().listen((_) {
      printLog('🔄 Review configuration changed - invalidating cache');
      _invalidateCache();
    });
  }

  // ==================== Logging Methods ====================

  void _logConfigurationChange(String? fromSite, String? toSite) {
    printLog(
        '🔄 Review configuration changed: ${fromSite ?? 'global'} → ${toSite ?? 'global'}');
  }

  void _logServiceCreation(ReviewServiceType serviceType, String? domain) {
    final domainInfo = domain != null ? ' ($domain)' : '';
    printLog('🚀 Review service created: ${serviceType.name}$domainInfo');
  }

  void _logConfigErrors(String? siteName, List<String> errors) {
    printLog('❌ Invalid review config for site $siteName:');
    for (final error in errors) {
      printLog('  - $error');
    }
    printLog('Falling back to global review configuration');

    // Enhanced error tracking for monitoring
    _trackConfigurationError(siteName, errors);
  }

  void _logConfigWarnings(String? siteName, List<String> warnings) {
    printLog('⚠️ Cảnh báo cấu hình review cho site $siteName:');
    for (final warning in warnings) {
      printLog('  - $warning');
    }

    // Enhanced warning tracking for monitoring
    _trackConfigurationWarning(siteName, warnings);
  }

  /// Track configuration errors for monitoring and analytics
  void _trackConfigurationError(String? siteName, List<String> errors) {
    // In production, this could send to analytics/monitoring service
    printLog(
        '🔍 Tracking config error - Site: $siteName, Errors: ${errors.length}');
  }

  /// Track configuration warnings for monitoring and analytics
  void _trackConfigurationWarning(String? siteName, List<String> warnings) {
    // In production, this could send to analytics/monitoring service
    printLog(
        '🔍 Tracking config warning - Site: $siteName, Warnings: ${warnings.length}');
  }

  // ==================== Cleanup ====================

  /// Dispose of resources and cancel subscriptions
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _cachedService = null;
  }
}
