import 'package:flutter/widgets.dart';

import '../../../models/entities/product.dart';
import '../../chat/vendor_chat.dart';
import '../widgets/detail_product_sliver_appbar.dart';

mixin DetailProductMixin<T extends StatefulWidget> on State<T> {
  final ValueNotifier<int> _selectIndexNotifier = ValueNotifier(0);

  ValueNotifier<int> get selectIndexNotifier => _selectIndexNotifier;
  bool get isLoading;
  Product get product;
  bool get enableVendorChat;

  @override
  void dispose() {
    selectIndexNotifier.dispose();
    super.dispose();
  }

  // Required to use computed because it is necessary
  // to reload the status of isLoading
  Widget get detailProductAppBarWidget => DetailProductSliverAppBar(
        isLoading: isLoading,
        product: product,
        onChangeImage: (p0) => _selectIndexNotifier.value = p0,
      );

  late final Widget? floatingActionButton = enableVendorChat
      ? Padding(
          padding: const EdgeInsets.only(bottom: 64),
          child: VendorChat(
            store: product.store,
            product: product,
          ),
        )
      : null;
}
