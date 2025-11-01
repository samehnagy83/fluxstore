import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';

import '../../../common/constants.dart';
import '../../../screens/common/app_bar_mixin.dart';
import 'store_layout.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return VendorListScreenState();
  }
}

class VendorListScreenState extends State<VendorListScreen>
    with
        AutomaticKeepAliveClientMixin,
        SingleTickerProviderStateMixin,
        AppBarMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return renderScaffold(
      routeName: RouteList.vendorList,
      backgroundColor: Theme.of(context).colorScheme.surface,
      secondAppBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          S.of(context).stores,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios,
                  ),
                ),
              )
            : null,
      ),
      child: const StoreLayout(),
    );
  }
}
