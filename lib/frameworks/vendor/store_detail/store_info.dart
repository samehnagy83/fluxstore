import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../../common/config.dart';
import '../../../widgets/common/index.dart';
import 'widgets/contact.dart';
import 'widgets/store_map.dart';

class StoreInfoWidget extends StatelessWidget {
  final Store store;

  const StoreInfoWidget({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            Contact(store: store),
            if (store.showDescription)
              ExpansionInfo(
                expand: true,
                title: S.of(context).description,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    child: HtmlWidget(
                      store.description ?? '',
                    ),
                  ),
                ],
              ),
            if (store.lat != null && store.long != null)
              ExpansionInfo(
                expand: kVendorConfig.expandStoreLocationByDefault,
                title: S.of(context).location,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                    ),
                    child: StoreMap(
                      store: store,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}
