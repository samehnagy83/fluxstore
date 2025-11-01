import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../models/entities/filter_sorty_by.dart';
import '../../models/index.dart'
    show BlogModel, FilterAttribute, ProductModel, SubAttribute;
import '../../modules/dynamic_layout/helper/helper.dart';
import '../../services/index.dart';
import 'filters/filters.dart';

class FilterWidget extends StatefulWidget {
  final Function({
    double? minPrice,
    double? maxPrice,
    List<String>? categoryId,
    String? categoryName,
    List<String>? tagId,
    String? listingLocationId,
    FilterSortBy? sortBy,
    bool? isSearch,
    List<String>? brandIds,
    Map<FilterAttribute, List<SubAttribute>>? attributes,
  })? onFilter;

  // Values
  final List<String>? categoryId;
  final List<String>? tagId;
  final List<String>? brandIds;
  final String? listingLocationId;
  final Map<FilterAttribute, List<SubAttribute>>? selectedAttributes;
  final double? minPrice;
  final double? maxPrice;
  final FilterSortBy? sortBy;

  /// Set true in case showing the Blog menu data inside Woo/Vendor app
  /// apply for the dynamic Blog on home screen.
  final bool isUseBlog;
  final bool isBlog;
  final ScrollController? controller;

  // UI controls
  final bool showSort;
  final bool showLayout;
  final bool showTag;
  final bool showBrand;
  final bool showCategory;
  final bool showPriceSlider;
  final bool showAttribute;
  final bool allowMultipleCategory;
  final bool allowMultipleTag;
  final bool allowMultiAttribute;
  final double? minFilterPrice;
  final double? maxFilterPrice;

  /// Used to close backdrop UI only, do not call filter function here
  final VoidCallback? onApply;

  const FilterWidget({
    super.key,
    this.onFilter,
    this.categoryId,
    this.tagId,
    this.brandIds,
    this.listingLocationId,
    this.selectedAttributes,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.isBlog = false,
    this.isUseBlog = false,
    this.controller,
    this.showSort = true,
    this.showLayout = true,
    this.showTag = true,
    this.showBrand = true,
    this.showCategory = true,
    this.showPriceSlider = true,
    this.showAttribute = true,
    this.allowMultipleCategory = false,
    this.allowMultipleTag = false,
    this.allowMultiAttribute = false,
    this.minFilterPrice,
    this.maxFilterPrice,
    this.onApply,
  });

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  bool get isBlog => widget.isBlog;

  void _onFilter({
    List<String>? categoryId,
    String? categoryName,
    List<String>? tagId,
    bool? isSearch,
    String? listingLocationId,
    List<String>? brandIds,
    FilterSortBy? sortBy,
    Map<FilterAttribute, List<SubAttribute>>? attributes,
    double? minPrice,
    double? maxPrice,
  }) =>
      widget.onFilter?.call(
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        categoryId: categoryId,
        categoryName: categoryName ?? '',
        tagId: tagId,
        brandIds: brandIds,
        isSearch: isSearch,
        listingLocationId: (listingLocationId?.isEmpty ?? false)
            ? null
            : listingLocationId ??
                context.read<ProductModel>().listingLocationId,
        attributes: attributes,
      );

  /// Filter support
  ServerConfig get _svConfig => ServerConfig();
  bool get _supportSort => !_svConfig.isHaravan;
  bool get _supportBrand => !_svConfig.isHaravan;
  bool get _supportPriceSlider =>
      !_svConfig.isHaravan && !_svConfig.isListingType && !_svConfig.isShopify;
  bool get _supportAttribute =>
      !_svConfig.isHaravan && !_svConfig.isListingType && !_svConfig.isShopify;
  bool get _supportTag => _svConfig.isHaravan == false;
  bool get _supportProductBackdrop =>
      !_svConfig.isListingType && !_svConfig.isHaravan;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (Layout.isDisplayDesktop(context))
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      if (Layout.isDisplayDesktop(context)) {
                        eventBus.fire(const EventOpenCustomDrawer());
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Icon(Icons.arrow_back_ios,
                        size: 22, color: Colors.white70),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    ServerConfig().isWordPress
                        ? context.select((BlogModel blogModel) =>
                                blogModel.categoryName) ??
                            S.of(context).blog
                        : S.of(context).products,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

          if (widget.showLayout) const LayoutFilterWidget(),

          if (widget.showSort && _supportSort)
            Services().widget.renderFilterSortBy(
              context,
              filterSortBy: widget.sortBy,
              showDivider: widget.showLayout,
              isBlog: isBlog,
              onFilterChanged: (filterSortBy) {
                _onFilter(sortBy: filterSortBy);
              },
            ),

          if (ServerConfig().isListingType)
            ListingLocationFilterWidget(
              listingLocationId: widget.listingLocationId,
              onFilter: (listingLocationId) {
                _onFilter(listingLocationId: listingLocationId ?? '');
              },
            ),

          if (_supportPriceSlider && widget.showPriceSlider)
            PriceSliderFilterWidget(
              currentMinPrice: widget.minPrice,
              currentMaxPrice: widget.maxPrice,
              minFilterPrice: widget.minFilterPrice,
              maxFilterPrice: widget.maxFilterPrice,
              onChanged: (minPrice, maxPrice) {
                _onFilter(
                  minPrice: minPrice,
                  maxPrice: maxPrice,
                );
              },
            ),

          if (widget.showCategory)
            CategoryFilterWidget(
              categoryId: widget.categoryId,
              isUseBlog: widget.isUseBlog,
              isBlog: isBlog,
              allowMultiple: widget.allowMultipleCategory,
              onFilter: (categoryIds) {
                _onFilter(
                  categoryId: categoryIds,
                  categoryName: null,
                  isSearch: false,
                );
              },
            ),

          if (widget.showBrand && _supportBrand)
            BrandFilterWidget(
              brandId: widget.brandIds,
              onChanged: (brandIds) {
                _onFilter(brandIds: brandIds);
              },
            ),

          /// filter by tags
          if (widget.showTag && _supportTag)
            TagFilterWidget(
              tagId: widget.tagId,
              isUseBlog: widget.isUseBlog,
              isBlog: isBlog,
              allowMultiple: widget.allowMultipleTag,
              onChanged: (tagIds) {
                _onFilter(tagId: tagIds);
              },
            ),

          if (_supportAttribute && widget.showAttribute)
            if (widget.allowMultiAttribute)
              MultiAttributeFilterWidget(
                selectedAttribute: widget.selectedAttributes,
                onChanged: (attrs) {
                  _onFilter(attributes: attrs);
                },
              )
            else
              AttributeFilterWidget(
                selectedAttribute: widget.selectedAttributes,
                onChanged: (attrs) {
                  _onFilter(attributes: attrs);
                },
              ),

          /// render Apply button
          if (_supportProductBackdrop &&
              Services().widget.enableProductBackdrop)
            Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 5,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ButtonTheme(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3.0),
                          ),
                        ),
                        onPressed: () {
                          widget.onApply?.call();
                        },
                        child: Text(
                          S.of(context).apply,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
