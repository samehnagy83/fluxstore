import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';

import '../../../common/constants.dart';
import '../../../models/entities/index.dart';
import '../../../services/service_config.dart';
import '../../../services/services.dart';

/// Mixin to handle Shopify-specific ReOrder functionality
mixin ShopifyReOrderMixin {
  /// Check if current framework is Shopify
  bool get isShopify => ServerConfig().type == ConfigType.shopify;

  /// Fetch Product details for Shopify ProductItems that need it
  Future<Map<String, ProductItem>> fetchShopifyProductDetails(
    Map<String, ProductItem> products,
    Function(String) onProgress,
  ) async {
    printLog(
        'fetchShopifyProductDetails: Starting with ${products.length} products');
    if (!isShopify) {
      printLog(
          'fetchShopifyProductDetails: Not Shopify, returning original products');
      return products;
    }

    final updatedProducts = <String, ProductItem>{};
    final itemsToFetch = <String, ProductItem>{};

    // Identify items that need product fetching
    for (var entry in products.entries) {
      final needsFetch = entry.value.needsProductFetch;
      printLog(
          'fetchShopifyProductDetails: Item ${entry.key} (${entry.value.name}) needsProductFetch: $needsFetch');
      if (needsFetch) {
        itemsToFetch[entry.key] = entry.value;
      } else {
        updatedProducts[entry.key] = entry.value;
      }
    }

    printLog(
        'fetchShopifyProductDetails: Items to fetch: ${itemsToFetch.length}, Already ready: ${updatedProducts.length}');

    if (itemsToFetch.isEmpty) {
      printLog(
          'fetchShopifyProductDetails: No items to fetch, returning original products');
      return products;
    }

    // Fetch product details for Shopify items in parallel
    onProgress('Fetching ${itemsToFetch.length} products...');

    // Create futures for all fetch operations
    final fetchFutures = itemsToFetch.entries.map((entry) async {
      final key = entry.key;
      final item = entry.value;

      try {
        printLog(
            'fetchShopifyProductDetails: Starting fetch for $key (${item.name})');

        final productDetails = await _fetchProductDetailsForItem(item);
        if (productDetails != null) {
          printLog(
              'fetchShopifyProductDetails: Successfully fetched product details for $key');
          // Update the ProductItem with fetched details
          item.product = productDetails;
          return MapEntry(key, item);
        } else {
          printLog(
              'fetchShopifyProductDetails: Failed to fetch product details for $key');
          // Keep original item even if fetch failed
          return MapEntry(key, item);
        }
      } catch (e) {
        printLog('Error fetching product details for $key: $e');
        // Keep original item on error
        return MapEntry(key, item);
      }
    }).toList();

    // Wait for all fetch operations to complete
    final fetchResults = await Future.wait(fetchFutures);

    // Add all fetched results to updatedProducts
    for (final result in fetchResults) {
      updatedProducts[result.key] = result.value;
    }

    printLog(
        'fetchShopifyProductDetails: Completed parallel fetch. Returning ${updatedProducts.length} products');
    return updatedProducts;
  }

  /// Get appropriate variation for Shopify ProductItem
  ProductVariation? getShopifyVariation(ProductItem productItem) {
    if (!isShopify || productItem.product == null) return null;

    // For Shopify, use the stored variationId to find the correct variation
    if (productItem.variationId != null) {
      return productItem.getSelectedVariation();
    }

    // Fallback to first available variation if no variationId
    // This happens with Customer Account API orders
    final variations = productItem.product?.variations;
    if (variations?.isNotEmpty == true) {
      return variations!.first;
    }

    return null;
  }

  /// Check if ProductItem has all required data for add to cart
  bool isProductItemReady(ProductItem productItem) {
    if (!isShopify) return productItem.product != null;

    // For Shopify, we need both product and variation data
    return productItem.product != null &&
        (productItem.product!.variations?.isNotEmpty ?? false);
  }

  /// Get error message for ProductItem that's not ready
  String getNotReadyErrorMessage(
      BuildContext context, ProductItem productItem) {
    if (productItem.product == null) {
      return S.of(context).productNotFound;
    }

    if (isShopify && (productItem.product!.variations?.isEmpty ?? true)) {
      return S.of(context).productVariationsNotAvailable;
    }

    return S.of(context).productNotReadyForReorder;
  }

  /// Handle Shopify-specific product type checking
  bool isAppointmentProduct(ProductItem productItem) {
    if (productItem.product == null) return false;

    // For Shopify, appointment products might have different type structure
    return productItem.product!.type == 'appointment';
  }

  /// Fetch Product details for Shopify ProductItems with enhanced progress tracking
  Future<Map<String, ProductItem>> fetchShopifyProductDetailsWithProgress(
    Map<String, ProductItem> products,
    Function(String) onProgress,
  ) async {
    printLog(
        'fetchShopifyProductDetailsWithProgress: Starting with ${products.length} products');
    if (!isShopify) {
      printLog(
          'fetchShopifyProductDetailsWithProgress: Not Shopify, returning original products');
      return products;
    }

    final updatedProducts = <String, ProductItem>{};
    final itemsToFetch = <String, ProductItem>{};

    // Identify items that need product fetching
    for (var entry in products.entries) {
      final needsFetch = entry.value.needsProductFetch;
      printLog(
          'fetchShopifyProductDetailsWithProgress: Item ${entry.key} (${entry.value.name}) needsProductFetch: $needsFetch');
      if (needsFetch) {
        itemsToFetch[entry.key] = entry.value;
      } else {
        updatedProducts[entry.key] = entry.value;
      }
    }

    printLog(
        'fetchShopifyProductDetailsWithProgress: Items to fetch: ${itemsToFetch.length}, Already ready: ${updatedProducts.length}');

    if (itemsToFetch.isEmpty) {
      printLog(
          'fetchShopifyProductDetailsWithProgress: No items to fetch, returning original products');
      return products;
    }

    // Track progress with completed count
    var completedCount = 0;
    final totalCount = itemsToFetch.length;

    onProgress('Fetching $totalCount products...');

    // Create futures for all fetch operations with progress tracking
    final fetchFutures = itemsToFetch.entries.map((entry) async {
      final key = entry.key;
      final item = entry.value;

      try {
        printLog(
            'fetchShopifyProductDetailsWithProgress: Starting fetch for $key (${item.name})');

        final productDetails = await _fetchProductDetailsForItem(item);

        // Update progress
        completedCount++;
        onProgress('Fetched $completedCount/$totalCount products...');

        if (productDetails != null) {
          printLog(
              'fetchShopifyProductDetailsWithProgress: Successfully fetched product details for $key');
          // Update the ProductItem with fetched details
          item.product = productDetails;
          return MapEntry(key, item);
        } else {
          printLog(
              'fetchShopifyProductDetailsWithProgress: Failed to fetch product details for $key');
          // Keep original item even if fetch failed
          return MapEntry(key, item);
        }
      } catch (e) {
        // Update progress even on error
        completedCount++;
        onProgress('Fetched $completedCount/$totalCount products...');

        printLog('Error fetching product details for $key: $e');
        // Keep original item on error
        return MapEntry(key, item);
      }
    }).toList();

    // Wait for all fetch operations to complete
    final fetchResults = await Future.wait(fetchFutures);

    // Add all fetched results to updatedProducts
    for (final result in fetchResults) {
      updatedProducts[result.key] = result.value;
    }

    onProgress('Completed fetching all products!');
    printLog(
        'fetchShopifyProductDetailsWithProgress: Completed parallel fetch. Returning ${updatedProducts.length} products');
    return updatedProducts;
  }

  /// Fetch Product details for a single ProductItem
  Future<Product?> _fetchProductDetailsForItem(ProductItem item) async {
    if (item.product != null) return item.product;
    if (item.productId == null) return null;

    try {
      final fetchedProduct = await Services().api.getProduct(item.productId!);
      return fetchedProduct;
    } catch (e) {
      printLog('Error fetching product details for ReOrder: $e');
      return null;
    }
  }
}
