import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';
import '../../../../common/config.dart';
import '../../../../models/entities/product.dart';
import '../../../../modules/dynamic_layout/config/product_config.dart';
import '../../../../widgets/product/product_card_view.dart';

enum ProductListType {
  list,
  grid,
}

class ShopProductListLayout extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final ProductListType type;
  final int? maxItems;

  const ShopProductListLayout({
    super.key,
    required this.products,
    required this.isLoading,
    this.type = ProductListType.list,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = Tools.isTablet(MediaQuery.of(context));
    final columns = isTablet ? 3 : 2;

    final itemWidth = _calculateItemWidth(screenWidth, columns);
    final itemHeight = _calculateItemHeight(itemWidth);

    final productConfig = ProductConfig.empty()..hideStore = true;
    final itemCount = isLoading ? 20 : (maxItems ?? products.length);

    return _buildProductList(
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      itemCount: itemCount,
      columns: columns,
      productConfig: productConfig,
    );
  }

  double _calculateItemWidth(double screenWidth, int columns) {
    final horizontalPadding =
        type == ProductListType.list ? 40 : (columns + 1) * 10;
    return (screenWidth - horizontalPadding) / columns;
  }

  double _calculateItemHeight(double itemWidth) {
    var height = itemWidth * kAdvanceConfig.ratioProductImage;
    height += kProductDetail.productListItemHeight;
    if (kProductDetail.showQuantityInList) height += 30;
    if (kProductCard.showCartButton) height += 30;
    return height;
  }

  Widget _buildProductList({
    required double itemWidth,
    required double itemHeight,
    required int itemCount,
    required int columns,
    required ProductConfig productConfig,
  }) {
    Widget itemBuilder(_, index) => ProductCard(
          item: isLoading ? Product.empty(index.toString()) : products[index],
          width: itemWidth,
          config: productConfig,
        );

    if (type == ProductListType.list) {
      return SizedBox(
        height: itemHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: itemBuilder,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: itemHeight,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
