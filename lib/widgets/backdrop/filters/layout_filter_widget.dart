import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';

import '../../../common/constants.dart';
import '../../../models/app_model.dart';
import 'widgets/container_filter.dart';

class LayoutFilterWidget extends StatefulWidget {
  const LayoutFilterWidget({
    super.key,
    this.isBlog = false,
  });

  final bool isBlog;

  @override
  State<LayoutFilterWidget> createState() => _LayoutFilterWidgetState();
}

class _LayoutFilterWidgetState extends State<LayoutFilterWidget> {
  bool get isBlog => widget.isBlog;

  String _getLocalizedLayoutName(BuildContext context, String? layout) {
    switch (layout) {
      case 'list':
        return S.of(context).list;
      case 'columns':
        return S.of(context).columns;
      case 'card':
        return S.of(context).card;
      case 'horizontal':
        return S.of(context).horizontal;
      case 'listTile':
        return S.of(context).listTile;
      case 'simpleList':
        return S.of(context).simpleList;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            S.of(context).layout,
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 5.0),

        /// render layout
        Selector<AppModel, String>(
          selector: (_, AppModel appModel) => appModel.productListLayout,
          builder: (_, String selectLayout, __) {
            final items = isBlog ? kBlogListLayout : kProductListLayout;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: List.generate(
                  items.length,
                  (index) {
                    final item = items[index];
                    final layout = item['layout'];
                    final image = item['image']?.toString() ?? '';

                    return Tooltip(
                      message: _getLocalizedLayoutName(context, layout),
                      child: GestureDetector(
                        onTap: () => context
                            .read<AppModel>()
                            .updateProductListLayout(layout),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: ContainerFilter(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(
                              bottom: 15,
                              left: 8,
                              right: 8,
                              top: 15,
                            ),
                            isBlog: isBlog,
                            isSelected: selectLayout == layout,
                            child: FluxImage(
                              imageUrl: image,
                              color: selectLayout == layout
                                  ? theme.primaryColor
                                  : theme.colorScheme.secondary
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
