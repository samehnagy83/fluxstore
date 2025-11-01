import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../shop_model/export.dart';
import 'shop_product_list_layout.dart';
import 'shop_product_list_screen.dart';

class Shop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSaleModel = Provider.of<ShopOnSaleModel>(context);
    final onLatestModel = Provider.of<ShopNewModel>(context);
    final onPopularModel = Provider.of<ShopPopularModel>(context);

    if ((onSaleModel.state == ShopModelState.loaded &&
            onLatestModel.state == ShopModelState.loaded &&
            onPopularModel.state == ShopModelState.loaded) &&
        (onSaleModel.products.isEmpty &&
            onLatestModel.products.isEmpty &&
            onPopularModel.products.isEmpty)) {
      return Center(
        child: Text(S.of(context).noData),
      );
    }

    return const SingleChildScrollView(
      child: Column(
        children: [
          ShopList.onSale(),
          ShopList.latest(),
          ShopList.popular(),
        ],
      ),
    );
  }
}

enum ShopListType { popular, latest, onSale }

class ShopList extends StatelessWidget {
  final ShopListType type;

  const ShopList.popular({super.key, this.type = ShopListType.popular});
  const ShopList.latest({super.key, this.type = ShopListType.latest});
  const ShopList.onSale({super.key, this.type = ShopListType.onSale});

  @override
  Widget build(BuildContext context) {
    void toShopList(String name, model) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        switch (type) {
          case ShopListType.popular:
            return ShopProductListScreen.popular(
              name: name,
              ctx: context,
            );
          case ShopListType.latest:
            return ShopProductListScreen.latest(
              name: name,
              ctx: context,
            );

          default:
            return ShopProductListScreen.onSale(
              name: name,
              ctx: context,
            );
        }
      }));
    }

    final theme = Theme.of(context);
    var title = S.of(context).onSale;
    var model;
    if (type == ShopListType.popular) {
      title = S.of(context).popular;
      model = Provider.of<ShopPopularModel>(context);
    }
    if (type == ShopListType.latest) {
      title = S.of(context).latestProducts;
      model = Provider.of<ShopNewModel>(context);
    }
    if (type == ShopListType.onSale) {
      model = Provider.of<ShopOnSaleModel>(context);
    }
    final maxLength = model.products.length < 10 ? model.products.length : 10;
    if (model.products.isEmpty && model.state == ShopModelState.loaded) {
      return const SizedBox();
    }
    return Container(
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (maxLength == 10)
                GestureDetector(
                    onTap: () => toShopList(title, model),
                    child: Text(S.of(context).seeAll,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Theme.of(context).primaryColor))),
            ],
          ),
          const SizedBox(height: 10.0),
          ShopProductListLayout(
            products: model.products,
            isLoading: model.state == ShopModelState.loading,
            maxItems: maxLength,
          ),
        ],
      ),
    );
  }
}
