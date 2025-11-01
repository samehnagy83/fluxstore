import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/config/models/cart_config.dart';
import '../../../common/constants.dart';
import '../../../common/tools.dart';
import '../../../common/tools/flash.dart';
import '../../../models/app_model.dart';
import '../../../models/cart/cart_item_meta_data.dart';
import '../../../models/cart/cart_model.dart';
import '../../../models/entities/index.dart';
import '../../../services/services.dart';
import '../../../widgets/common/loading_body.dart';
import '../mixins/shopify_reorder_mixin.dart';

/// Enhanced ReOrderItemList with Shopify support
class ShopifyReOrderItemList extends StatefulWidget {
  final List<ProductItem> lineItems;

  const ShopifyReOrderItemList({
    super.key,
    required this.lineItems,
  });

  @override
  State<ShopifyReOrderItemList> createState() => _ShopifyReOrderItemListState();
}

class _ShopifyReOrderItemListState extends State<ShopifyReOrderItemList>
    with ShopifyReOrderMixin {
  final Map<String, String> _errorMessages = {};
  final _pageController = PageController();

  Map<String, ProductItem> _products = {};

  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeProducts();
  }

  Future<void> _initializeProducts() async {
    printLog('ShopifyReOrder: Starting initialization...');
    printLog('ShopifyReOrder: LineItems count: ${widget.lineItems.length}');

    // Initialize products map
    for (var item in widget.lineItems) {
      final id = item.id;
      final productId = item.productId;
      printLog(
          'ShopifyReOrder: Processing item - id: $id, name: ${item.name}, productId: $productId');

      // Create unique key: use variationId if available, then id, then productId
      // This ensures each variant has a unique key
      final key = item.variationId ?? id ?? productId;
      if (key == null) {
        printLog('ShopifyReOrder: Skipping item with null id and productId');
        continue;
      }

      printLog('ShopifyReOrder: Adding item with key: $key');
      _products[key] = item;
    }

    printLog('ShopifyReOrder: Products map size: ${_products.length}');
    printLog('ShopifyReOrder: Is Shopify: $isShopify');

    // Fetch Shopify product details if needed
    if (isShopify) {
      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }

      try {
        printLog('ShopifyReOrder: Starting fetchShopifyProductDetails...');
        _products = await fetchShopifyProductDetailsWithProgress(
          _products,
          (message) {
            printLog('ShopifyReOrder: Progress - $message');
          },
        );
        printLog(
            'ShopifyReOrder: Finished fetchShopifyProductDetails. Final products count: ${_products.length}');
      } catch (e) {
        printLog('Error initializing Shopify products: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
      printLog(
          'ShopifyReOrder: Initialization completed. Final state - products: ${_products.length}, isInitializing: $_isInitializing');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return kLoadingWidget(context);
    }

    return LoadingBody(
      isLoading: _isLoading,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 8.0),
              alignment: Alignment.center,
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValueOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildProductList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    printLog('_buildProductList: Building with ${_products.length} products');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).reOrder,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(S.of(context).cancel),
              ),
            ],
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context).noProductsFoundInOrder,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _products.length,
                  padding: const EdgeInsets.only(
                    bottom: kToolbarHeight,
                    left: 16.0,
                    right: 16.0,
                  ),
                  itemBuilder: (context, index) {
                    final product = _products.values.elementAt(index);
                    // Use same key logic as in initState: variationId > id > productId
                    final key =
                        product.variationId ?? product.id ?? product.productId;

                    return _buildProductItem(product, key, index);
                  },
                ),
        ),
        _buildAddToCartButton(),
      ],
    );
  }

  Widget _buildProductItem(ProductItem product, String? key, int index) {
    // Handle Shopify-specific product readiness check
    final isReady = isProductItemReady(product);
    final isInStock = _isProductInStock(product);

    var addonsOptions = <String, dynamic>{};
    if (product.addonsOptions.isNotEmpty) {
      for (var element in product.addonsOptions.keys) {
        addonsOptions[element] = Tools.getFileNameFromUrl(
          product.addonsOptions[element]!,
        );
      }
    }

    return Dismissible(
      key: Key('dismissible_${product.variationId ?? UniqueKey().toString()}'),
      onDismissed: (direction) {
        // Remove the item from all maps
        _products.remove(key);
        _errorMessages.remove(key);

        // Update the UI
        setState(() {});

        // Close dialog if no products left
        if (_products.isEmpty) {
          Navigator.of(context).pop();
        }
      },
      child: ColorFiltered(
        colorFilter: isInStock
            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
            : const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, // Red channel
                0.2126, 0.7152, 0.0722, 0, 0, // Green channel
                0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
                0, 0, 0, 1, 0, // Alpha channel
              ]),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValueOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.withValueOpacity(0.2),
                      child: ImageResize(
                        url: product.featuredImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name ?? '',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${S.of(context).quantity}: ${product.quantity}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 4.0),
                        _buildPriceDisplay(context, product),
                        const SizedBox(height: 4.0),
                        _buildStockStatus(context, product),
                        const SizedBox(height: 4.0),
                        _buildVariantDisplay(context, product),
                        if (!isReady) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            getNotReadyErrorMessage(context, product),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (_errorMessages[key]?.isNotEmpty == true) ...[
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _errorMessages[key] == 'added'
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    _errorMessages[key] == 'added'
                        ? S.of(context).addedToCart
                        : _errorMessages[key]!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _errorMessages[key] == 'added'
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onErrorContainer,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _products.isNotEmpty ? _addToCart : null,
          child: Text(S.of(context).addToCart),
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    setState(() {
      _isLoading = true;
    });

    final cartModel = Provider.of<CartModel>(context, listen: false);
    var hasSuccess = false;
    final addedProducts = <String>[];
    final failedProducts = <String>[];

    for (var id in _products.keys) {
      if (_errorMessages[id] == 'added') continue;

      final productItem = _products[id]!;
      final productName = productItem.name ?? 'Unknown Product';

      // Check if product is in stock
      if (!_isProductInStock(productItem)) {
        _errorMessages[id] = S.of(context).outOfStock;
        failedProducts.add(productName);
        continue;
      }

      // Check if product is ready for Shopify
      if (!isProductItemReady(productItem)) {
        final errorMsg = getNotReadyErrorMessage(context, productItem);
        _errorMessages[id] = errorMsg;
        failedProducts.add(productName);
        continue;
      }

      final product = productItem.product!;

      // Get appropriate variation for Shopify
      ProductVariation? variation;
      if (isShopify && product.isVariableProduct) {
        variation = getShopifyVariation(productItem);
      }

      try {
        final (success, message) = await cartModel.addProductToCart(
          context: context,
          product: product,
          quantity: productItem.quantity,
          cartItemMetaData: CartItemMetaData(
            variation: variation,
          ),
        );

        if (message.isNotEmpty) {
          _errorMessages[id] = message;
          failedProducts.add(productName);
        } else if (success) {
          _errorMessages[id] = 'added';
          addedProducts.add(productName);
          hasSuccess = true;
        }
      } catch (e) {
        _errorMessages[id] = 'Error adding to cart';
        failedProducts.add(productName);
        printLog('Error adding product to cart: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });

    // Close dialog if at least one product was added successfully
    if (hasSuccess) {
      Navigator.of(context).pop(true);

      // Show success message with added products
      _showAddToCartResult(addedProducts, failedProducts);
    }
  }

  /// Show result message after adding products to cart
  void _showAddToCartResult(
      List<String> addedProducts, List<String> failedProducts) {
    if (!mounted) return;

    var message = '';

    if (addedProducts.isNotEmpty) {
      if (addedProducts.length == 1) {
        message = 'Added "${addedProducts.first}" to cart successfully';
      } else {
        message =
            'Added ${addedProducts.length} products to cart successfully:\n';
        message += addedProducts.map((name) => '• $name').join('\n');
      }
    }

    if (failedProducts.isNotEmpty) {
      if (message.isNotEmpty) message += '\n\n';
      if (failedProducts.length == 1) {
        message += 'Failed to add "${failedProducts.first}"';
      } else {
        message += 'Failed to add ${failedProducts.length} products:\n';
        message += failedProducts.map((name) => '• $name').join('\n');
      }
    }

    if (message.isNotEmpty) {
      FlashHelper.message(context, message: message);
    }
  }

  /// Check if product is in stock (available for sale)
  bool _isProductInStock(ProductItem productItem) {
    if (productItem.product == null) {
      return true; // Assume in stock if no product data
    }

    final product = productItem.product!;

    // For Shopify, check variant-level stock if we have a selected variant
    if (productItem.isShopifyItem) {
      final selectedVariation = getShopifyVariation(productItem);
      if (selectedVariation != null) {
        // Check if variant is available for sale (not out of stock)
        return selectedVariation.inStock ?? true;
      }
    }

    // Fallback to product-level stock check
    return product.checkInStock() ?? true;
  }

  /// Check if product is on backorder (available for sale but quantity <= 0)
  bool _isProductOnBackorder(ProductItem productItem) {
    if (productItem.product == null) {
      return false;
    }

    // For Shopify, check variant-level backorder status
    if (productItem.isShopifyItem) {
      final selectedVariation = getShopifyVariation(productItem);
      if (selectedVariation != null) {
        final isAvailableForSale = selectedVariation.inStock ?? true;
        final quantity = selectedVariation.stockQuantity ?? 0;

        // On backorder: available for sale but quantity <= 0
        return isAvailableForSale && quantity <= 0;
      }
    }

    // Fallback to product-level backorder check
    return false; // For non-Shopify products, use old logic
  }

  /// Build stock status widget
  Widget _buildStockStatus(BuildContext context, ProductItem productItem) {
    if (productItem.product == null) return const SizedBox.shrink();

    final isInStock = _isProductInStock(productItem);
    final isOnBackorder = _isProductOnBackorder(productItem);

    // Determine stock status based on Shopify logic:
    // 1. availableForSale: false -> Out of Stock
    // 2. availableForSale: true + quantity <= 0 -> On Backorder
    // 3. availableForSale: true + quantity > 0 -> In Stock (no status shown)

    if (!isInStock) {
      // Out of Stock: availableForSale = false
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Text(
          S.of(context).outOfStock,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (isOnBackorder) {
      // On Backorder: availableForSale = true + quantity <= 0
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Text(
          S.of(context).backOrder,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // In Stock: no status widget shown
    return const SizedBox.shrink();
  }

  /// Build variant attributes display
  Widget _buildVariantDisplay(BuildContext context, ProductItem productItem) {
    final selectedVariation = productItem.getSelectedVariation();

    if (selectedVariation == null || productItem.product == null) {
      return const SizedBox.shrink();
    }

    // Use Services().widget.renderVariantCartItem to display variant attributes
    return Services().widget.renderVariantCartItem(
          context,
          productItem.product!,
          selectedVariation,
          null,
          style: AttributeProductCartStyle.normal,
        );
  }

  Widget _buildPriceDisplay(BuildContext context, ProductItem productItem) {
    final appModel = context.read<AppModel>();
    final currency = appModel.currencyCode;
    final currencyRate = appModel.currencyRate;

    // Get price from ProductItem or Product/Variant
    String? priceString;

    final selectedVariation = productItem.getSelectedVariation();

    // 1. Try to get price from ProductItem.total first (this is the order price - most accurate)
    if (productItem.total != null && productItem.total!.isNotEmpty) {
      priceString = PriceTools.getCurrencyFormatted(
        productItem.total,
        currencyRate,
        currency: currency,
      );
    }
    // 2. Fallback to variant price if available
    else if (selectedVariation != null) {
      priceString = PriceTools.getVariantPriceProductValue(
        selectedVariation,
        currencyRate,
        currency,
        onSale: true,
      );
    }
    // 3. Final fallback to Product price
    else if (productItem.product?.price != null &&
        productItem.product!.price!.isNotEmpty) {
      priceString = PriceTools.getCurrencyFormatted(
        productItem.product!.price,
        currencyRate,
        currency: currency,
      );
    }

    if (priceString == null || priceString.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      priceString,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
