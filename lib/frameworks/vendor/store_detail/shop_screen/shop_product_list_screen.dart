import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../common/constants.dart';
import '../shop_model/export.dart';
import 'shop_product_list_layout.dart';

enum ShopType { category, onSale, latest, popular }

class ShopProductListScreen extends StatefulWidget {
  final ShopType? type;
  final String? name;
  final BuildContext? ctx;
  const ShopProductListScreen({super.key, this.type, this.name, this.ctx});
  const ShopProductListScreen.category(
      {super.key, this.type = ShopType.category, this.name, required this.ctx});
  const ShopProductListScreen.onSale(
      {super.key, this.type = ShopType.onSale, this.name, required this.ctx});
  const ShopProductListScreen.latest(
      {super.key, this.type = ShopType.latest, this.name, required this.ctx});
  const ShopProductListScreen.popular(
      {super.key, this.type = ShopType.popular, this.name, required this.ctx});

  @override
  State<ShopProductListScreen> createState() => _ShopProductListScreenState();
}

class _ShopProductListScreenState extends State<ShopProductListScreen> {
  final _controller = RefreshController();
  Future<void> _onLoading(model) async {
    final list = await model.loadProducts();

    if (list.isEmpty) {
      _controller.loadNoData();
      return;
    }
    _controller.loadComplete();
  }

  Widget _listProductWidget(ShopModel model) {
    final theme = Theme.of(context);
    final isEmpty =
        model.products.isEmpty && model.state == ShopModelState.loaded;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.name ?? ''),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: SmartRefresher(
          controller: _controller,
          enablePullDown: false,
          enablePullUp: true,
          onLoading: () => _onLoading(model),
          footer: kCustomFooter(context),
          child: isEmpty
              ? Center(child: Text(S.of(context).noData))
              : ShopProductListLayout(
                  products: model.products,
                  isLoading: model.state == ShopModelState.loading,
                  type: ProductListType.grid,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var model;

    switch (widget.type) {
      case ShopType.category:
        model = Provider.of<ShopCategoryModel>(widget.ctx!, listen: false);
        return ChangeNotifierProvider<ShopCategoryModel>.value(
            value: model,
            child: Consumer<ShopCategoryModel>(
                builder: (_, model, __) => _listProductWidget(model)));
      case ShopType.latest:
        model = Provider.of<ShopNewModel>(widget.ctx!, listen: false);
        return ChangeNotifierProvider<ShopNewModel>.value(
            value: model,
            child: Consumer<ShopNewModel>(
                builder: (_, model, __) => _listProductWidget(model)));
      case ShopType.onSale:
        model = Provider.of<ShopOnSaleModel>(widget.ctx!, listen: false);
        return ChangeNotifierProvider<ShopOnSaleModel>.value(
            value: model,
            child: Consumer<ShopOnSaleModel>(
                builder: (_, model, __) => _listProductWidget(model)));
      default:
        model = Provider.of<ShopPopularModel>(widget.ctx!, listen: false);
        return ChangeNotifierProvider<ShopPopularModel>.value(
            value: model,
            child: Consumer<ShopPopularModel>(
                builder: (_, model, __) => _listProductWidget(model)));
    }
  }
}
