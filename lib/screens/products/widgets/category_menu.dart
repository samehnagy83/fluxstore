import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/extensions/list_categories_extension.dart';
import '../../../models/index.dart';
import '../../../services/services.dart';
import '../filter_mixin/products_filter_mixin.dart';
import 'item_category.dart';

class ProductCategoryMenu extends StatefulWidget {
  /// Whether to show images in the category menu
  final bool imageLayout;

  /// List of selected category IDs
  final List<String>? selectedCategories;

  /// Callback when a category is tapped
  final Function(String?)? onTap;

  /// Padding for the category menu
  final EdgeInsetsGeometry? padding;

  /// Style of the category menu (menu or tab)
  final ProductCategoryMenuStyle style;

  /// Delegate for category menu operations
  final CategoryMenuDelegate? categoryMenuDelegate;

  /// Only support ProductCategoryMenuStyle.tab
  final bool categoryMenuShowDepth;

  /// Callback when navigating to a category
  /// Parameters: categoryId, parentCategoryId, hasChild
  final void Function(
      String? categoryId, String? parentCategoryId, bool hasChild)? onPush;

  final List<StackPathCategory> Function() getStackSelectedCategory;

  const ProductCategoryMenu({
    super.key,
    this.imageLayout = false,
    this.selectedCategories,
    this.onTap,
    this.padding,
    this.style = ProductCategoryMenuStyle.menu,
    this.categoryMenuDelegate,
    this.onPush,
    required this.getStackSelectedCategory,
    this.categoryMenuShowDepth = false,
  });

  @override
  StateProductCategoryMenu createState() => StateProductCategoryMenu();
}

class StateProductCategoryMenu extends State<ProductCategoryMenu> {
  final _loadingController = ValueNotifier<bool>(false);

  /// Access to the category model
  CategoryModel get _categoryModel => context.read<CategoryModel>();

  /// Controller for scrolling to specific category
  final AutoScrollController _scrollController = AutoScrollController();

  /// List of subcategories for the selected category
  List<Category> _listSubCategory = <Category>[];

  /// Parent ID of the selected category
  String? parentOfSelectedCategoryId;

  /// Currently selected category
  Category? _selectedCategory;

  /// Whether the first scroll animation has completed
  var firstJumpDone = false;

  /// Whether the selected category has changed
  bool changedCategory = true;

  /// Whether to show category images from config
  bool get categoryImageMenu => kAdvanceConfig.categoryImageMenu;

  /// Only support ProductCategoryMenuStyle.tab
  bool get showDepth => widget.style.isTab && widget.categoryMenuShowDepth;

  /// Get the current level of the selected category
  int get currentCategoryLevel {
    return _categoryModel.getCategoryLevel(_selectedCategory?.id ?? '');
  }

  Category? getCategoryById(String id) {
    return _categoryModel.getCategoryById(id);
  }

  /// Get subcategories from local data
  List<Category> _getSubCategories(String? id) {
    if (id == null) {
      return [];
    }

    return _categoryModel.getSubCategory(id);
  }

  /// Fetch subcategories from API when enableLargeCategories is true
  /// or from local data when it's false
  Future<List<Category>> _fetchSubCategories(String? id) async {
    Future<List<Category>> fetch() async {
      // Return empty list for null ID
      if (id == null) return <Category>[];

      // If large categories feature is disabled, use local data
      if (!kEnableLargeCategories) {
        return _getSubCategories(id);
      }

      try {
        // Check cache first to avoid unnecessary API calls
        if (_categoryModel.subOfCategory[id] != null) {
          return _categoryModel.subOfCategory[id]!;
        }

        _loadingController.value = true;
        // Fetch from API with pagination
        final response = await Services().api.getSubCategories(
              page: 1,
              limit: 100, // Fetch a reasonable number of categories
              parentId: id,
            );

        // Process and cache the result
        final result = response.data ?? <Category>[];
        _categoryModel.subOfCategory[id] = result;
        return result.toList();
      } catch (e) {
        printLog('Error fetching subcategories: $e');
        // Fallback to local data if API call fails
        return _getSubCategories(id);
      }
    }

    late List<Category> listCategories;

    listCategories = await fetch();

    _loadingController.value = false;

    return listCategories;
  }

  /// Animate to the selected category in the horizontal list
  void _animateToCategory(int index) {
    // Skip animation if already done and category hasn't changed
    if (firstJumpDone && changedCategory == false) return;

    // Schedule animation after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Add a small delay for smoother animation
      Future.delayed(const Duration(milliseconds: 200)).then((_) {
        _scrollController.scrollToIndex(
          index,
          preferPosition: AutoScrollPosition.middle,
        );
        firstJumpDone = true;
        changedCategory = false;
      });
    });
  }

  /// Get the parent ID of the parent category
  /// Used by the category menu delegate
  String? _onGetIdCategoryParent() {
    final itemsSelected = widget.selectedCategories ?? [];

    // Only process if exactly one category is selected
    if (itemsSelected.length == 1) {
      final categoryId = itemsSelected.first;
      final subCtg = _getSubCategories(categoryId);
      final parent = getParentCategories(categoryId);

      // If the category has subcategories, return its parent
      if (subCtg.isNotEmpty) {
        return parent;
      }

      // If the category has a parent, return the parent of that parent
      if (parent != null) {
        return getParentCategories(parent);
      }
    }

    return null;
  }

  /// Handle category selection
  void _onSelectCategory(Category category) {
    _selectedCategory = category;
    final categoryId = category.id;
    final parentCategoryId = category.parent;
    final listCtgSelected = widget.selectedCategories ?? [];

    // Only process if the category is not already selected
    if (categoryId != null && !listCtgSelected.contains(categoryId)) {
      // Mark that the category has changed
      changedCategory = true;

      if (kEnableLargeCategories) {
        widget.onTap?.call(categoryId);

        // For large categories, fetch subcategories from API
        _fetchSubCategories(categoryId).then((subcategories) {
          _listSubCategory = subcategories.toList();
          // Notify the parent widget about the selection

          // Notify about navigation with subcategory information
          widget.onPush?.call(
            categoryId,
            parentCategoryId,
            subcategories.isNotEmpty,
          );
        });
      } else {
        // Notify the parent widget about the selection
        widget.onTap?.call(categoryId);
        // For normal mode, get subcategories from local data
        _listSubCategory = _getSubCategories(categoryId);

        // Notify about navigation with subcategory information
        widget.onPush?.call(
          categoryId,
          parentCategoryId,
          _listSubCategory.isNotEmpty,
        );
      }
    }
  }

  /// Load category settings for the selected category ID
  /// This includes fetching subcategories and parent information
  Future<void> _loadSetting(String ctgId) async {
    // Get the parent ID of the selected category
    parentOfSelectedCategoryId = getParentCategories(ctgId);

    // Load subcategories based on the enableLargeCategories setting
    if (kEnableLargeCategories) {
      // For large categories, fetch subcategories from API
      final listSubCategory = (await _fetchSubCategories(ctgId)).toList();
      if (parentOfSelectedCategoryId != null) {
        _listSubCategory.clear();
      }

      _listSubCategory = listSubCategory.toList();
    } else {
      // For normal mode, get subcategories from local data
      _listSubCategory = _getSubCategories(ctgId);
    }

    // Get the selected category object
    _selectedCategory = getCategoryById(ctgId);
  }

  @override
  void initState() {
    super.initState();
    widget.categoryMenuDelegate?.onGetIdCategoryParent = _onGetIdCategoryParent;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryModel>(
      builder: (context, categoryModel, child) {
        // Show loading indicator while category data is loading
        if (categoryModel.isLoading) {
          return Center(child: kLoadingWidget(context));
        }

        // Validate selected categories
        final selectedCategoryIds = widget.selectedCategories;
        if (selectedCategoryIds == null ||
            selectedCategoryIds.isEmpty ||
            selectedCategoryIds.length > 1) {
          return const SizedBox(); // No valid selection, return empty widget
        }

        final selectedCategoryId = selectedCategoryIds.first;

        // Use FutureBuilder to handle async loading of category settings
        return FutureBuilder<void>(
          future: _loadSetting(selectedCategoryId),
          builder: (context, snapshot) {
            return ValueListenableBuilder<bool>(
                valueListenable: _loadingController,
                builder: (context, isLoading, child) {
                  var categoryId = _selectedCategory?.id ?? selectedCategoryId;
                  var idParent = _selectedCategory?.parent;

                  final listStack = widget.getStackSelectedCategory();

                  if (showDepth) {
                    var firstParent = idParent;
                    var firstCategory = categoryId;

                    if (listStack.isNotEmpty) {
                      final ctgLevel1 = listStack.first;
                      firstParent = ctgLevel1.parentCategoryId;
                      firstCategory = ctgLevel1.categoryId;
                    }

                    if (firstParent != null) {
                      var level = _categoryModel.getCategoryLevel(categoryId);
                      if (level != 0) {
                        final bodyLevel1 =
                            _renderParentForLevel1(firstParent, firstCategory);
                        final subCategory = _getSubCategories(categoryId);
                        final categorySelected = _selectedCategory?.id;
                        final parentCategorySelected =
                            _selectedCategory?.parent;

                        if (bodyLevel1 != null) {
                          return Column(
                            children: [
                              bodyLevel1,
                              if (isLoading)
                                _loadingWidget()
                              else if (subCategory.isNotEmpty || level > 1) ...[
                                const Divider(height: 5),
                                if (subCategory.isNotEmpty)
                                  _renderWithSubCategory(
                                    categoryId,
                                    showImage: true,
                                  )
                                else if (parentCategorySelected != null &&
                                    categorySelected != null)
                                  _renderWithSubCategory(
                                    parentCategorySelected,
                                    showImage: true,
                                  ),
                              ],
                            ],
                          );
                        }
                      }
                    }
                  }
                  // Determine which rendering method to use based on category structure
                  if (['0', null, '-1'].contains(idParent)) {
                    // Case 1: Category has no parent (top-level category)
                    final widgetRender =
                        _renderWhenParentOfSelectedCategoryIdIsNull(categoryId);

                    if (widgetRender != null) {
                      return widgetRender;
                    }

                    if (isLoading) {
                      return _loadingWidget();
                    }
                  }

                  final listSubCate = _categoryModel.getSubCategory(categoryId);

                  // Case 2: Category has no subcategories
                  if (listSubCate.isEmpty && currentCategoryLevel == 1) {
                    return _renderWhenSelectedCategoryNotYetSubCategory(
                      categoryId,
                    );
                  }

                  // Case 3: Category has subcategories
                  return _renderWithSubCategory(categoryId);
                });
          },
        );
      },
    );
  }

  Widget _loadingWidget() {
    return const Center(
      child: SizedBox(
        width: 50,
        height: 50,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }

  /// Render categories when the selected category has no parent
  /// This is typically for top-level categories
  Widget? _renderParentForLevel1(String parentCategoryId, String categoryId) {
    final subCtg = _getSubCategories(parentCategoryId);
    var category = getCategoryById(parentCategoryId);

    // Create a "See All" option as the first item
    category = category?.copyWith(name: S.of(context).seeAll);

    // Combine the "See All" option with subcategories
    final categories =
        List<Category>.from([if (category != null) category, ...subCtg]);

    return _renderListCategories(categories, categoryId, false);
  }

  /// Render a list of categories with the selected category highlighted
  /// This method handles both tab style and horizontal list style
  Widget _renderListCategories(
    List<Category> categories,
    String selectedCategoryId,
    bool showImage,
  ) {
    // Find the index of the selected category
    final selectedIndex =
        categories.indexWhere((o) => o.id == selectedCategoryId);

    // Animate to the selected category
    _animateToCategory(selectedIndex);

    // Render as tabs if tab style is selected
    if (widget.style.isTab) {
      return _buildTabStyleCategories(categories, selectedIndex, showImage);
    }

    // Otherwise render as horizontal list
    return _buildHorizontalListCategories(categories);
  }

  /// Build categories in tab style
  Widget _buildTabStyleCategories(
    List<Category> categories,
    int selectedIndex,
    bool showImage,
  ) {
    if (categories.isEmpty) return const SizedBox();

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: showImage ? 130 : 50,
          child: DefaultTabController(
            length: categories.length,
            key: ValueKey(
                'renderCtgMenu${categories.length}-${categories.isNotEmpty ? categories.first.id : ''}'),
            initialIndex: selectedIndex > 0 ? selectedIndex : 0,
            child: TabBar(
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
              indicatorColor: showImage
                  ? Colors.transparent
                  : Theme.of(context).primaryColor,
              onTap: (value) => _onSelectCategory(categories[value]),
              tabs: List.generate(
                categories.length,
                (int index) {
                  final category = categories[index];
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: showImage ? 8 : 16),
                    child: showImage
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        width: 1.5,
                                        color:
                                            category.id == _selectedCategory?.id
                                                ? Theme.of(context).primaryColor
                                                : Colors.transparent)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (category.image?.isNotEmpty ?? false)
                                      ? FluxImage(
                                          imageUrl: category.image!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.image),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(category.displayName),
                            ],
                          )
                        : Text(category.displayName),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build categories in horizontal list style
  Widget _buildHorizontalListCategories(List<Category> categories) {
    // Early return for empty categories
    if (categories.isEmpty) return const SizedBox();

    final showImageMenu = categoryImageMenu && widget.imageLayout;
    final theme = Theme.of(context);

    // Extract padding once
    final padding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: padding,
          color: theme.colorScheme.surface,
          alignment: AlignmentDirectional.centerStart,
          constraints: const BoxConstraints(minHeight: 40),
          height: showImageMenu ? 130 : 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            // Avoid shrinkWrap for better performance
            controller: _scrollController,
            // Use cacheExtent to improve scrolling performance
            cacheExtent: 300,
            itemBuilder: (context, index) {
              final category = categories[index];
              // Use const constructor where possible
              return AutoScrollTag(
                key: ValueKey(index),
                index: index,
                controller: _scrollController,
                child: ItemCategory(
                  categoryId: category.id,
                  categoryName: category.name ?? '',
                  categoryImage: showImageMenu ? category.image : null,
                  selectedCategories: widget.selectedCategories,
                  onTap: (_) => _onSelectCategory(category),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Render categories when the selected category has no parent
  /// This is typically for top-level categories
  Widget? _renderWhenParentOfSelectedCategoryIdIsNull(
      String selectedCategoryId) {
    // If the selected category has subcategories, show them
    if (_listSubCategory.isNotEmpty) {
      // Create a "See All" option as the first item
      _selectedCategory =
          _selectedCategory!.copyWith(name: S.of(context).seeAll);

      // Combine the "See All" option with subcategories
      final categories =
          List<Category>.from([_selectedCategory!, ..._listSubCategory]);
      return _renderListCategories(categories, selectedCategoryId, false);
    }

    // If this is the first time and the category has no subcategories,
    // try to find its parent for proper navigation
    if (firstJumpDone == false) {
      parentOfSelectedCategoryId = getParentCategories(selectedCategoryId);
    }

    // Return null to let the caller handle this case
    return null;
  }

  /// Render categories when the selected category doesn't have subcategories
  /// In this case, we show sibling categories (categories with the same parent)
  Widget _renderWhenSelectedCategoryNotYetSubCategory(
      String selectedCategoryId) {
    // Get the parent category with "See All" label
    final parentCategory =
        getCategoryById(parentOfSelectedCategoryId.toString())
            ?.copyWith(name: S.of(context).seeAll);

    // If parent category doesn't exist, show empty widget
    if (parentCategory == null) {
      return const SizedBox(width: double.infinity);
    }

    // For normal mode (not large categories)
    if (!kEnableLargeCategories) {
      return _renderSiblingCategoriesFromLocal(
        parentCategory,
        selectedCategoryId,
      );
    }

    // For large categories mode, fetch from API
    return _renderSiblingCategoriesFromAPI(
      parentCategory,
      selectedCategoryId,
    );
  }

  /// Render sibling categories from local data
  Widget _renderSiblingCategoriesFromLocal(
    Category parentCategory,
    String selectedCategoryId,
  ) {
    final siblingCategories = _getSubCategories(parentOfSelectedCategoryId);

    // If there are not enough categories and no parent, show empty widget
    if (siblingCategories.length < 2 && parentOfSelectedCategoryId == null) {
      return const SizedBox(width: double.infinity);
    }

    // Add parent as first item and render
    siblingCategories.insert(0, parentCategory);
    return _renderListCategories(
      siblingCategories,
      selectedCategoryId,
      false,
    );
  }

  /// Render sibling categories fetched from API
  Widget _renderSiblingCategoriesFromAPI(
    Category parentCategory,
    String selectedCategoryId,
  ) {
    // Since we already have the parent ID and potentially loaded the subcategories,
    // we can use the cached data directly
    final siblingCategories = _getSubCategories(parentOfSelectedCategoryId);

    // If there are not enough categories and no parent, show empty widget
    if (siblingCategories.length < 2 && parentOfSelectedCategoryId == null) {
      return const SizedBox(width: double.infinity);
    }

    // Add parent as first item and render
    final categories = [parentCategory, ...siblingCategories].toList();
    return _renderListCategories(
      categories,
      selectedCategoryId,
      false,
    );
  }

  /// Render the selected category with its subcategories
  Widget _renderWithSubCategory(String selectedCategoryId,
      {bool showImage = false}) {
    // Get the selected category with "See All" label
    final selectedCategory = getCategoryById(selectedCategoryId.toString());

    // If category doesn't exist, show empty widget
    if (selectedCategory == null) {
      return const SizedBox(width: double.infinity);
    }

    // For normal mode (not large categories)
    if (!kEnableLargeCategories) {
      return _renderSubcategoriesFromLocal(
        selectedCategory,
        selectedCategoryId,
        showImage,
      );
    }

    // For large categories mode, fetch from API
    return _renderSubcategoriesFromAPI(
      selectedCategory,
      selectedCategoryId,
      showImage,
    );
  }

  /// Render subcategories from local data
  Widget _renderSubcategoriesFromLocal(
    Category selectedCategory,
    String selectedCategoryId,
    bool showImage,
  ) {
    final subcategories = _getSubCategories(selectedCategoryId);

    var category = selectedCategory.copyWith();
    if (subcategories.isNotEmpty) {
      category = category.copyWith(name: S.of(context).seeAll);
    }

    // Add selected category as first item and render
    subcategories.insert(0, category);
    return _renderListCategories(subcategories, selectedCategoryId, showImage);
  }

  /// Render subcategories fetched from API
  Widget _renderSubcategoriesFromAPI(
    Category selectedCategory,
    String selectedCategoryId,
    bool showImage,
  ) {
    // Since we already loaded subcategories in _loadSetting,
    // we can use the cached data directly instead of making another API call
    final subcategories = _getSubCategories(selectedCategoryId);

    var category = selectedCategory.copyWith();
    if (subcategories.isNotEmpty) {
      category = category.copyWith(name: S.of(context).seeAll);
    }

    // Add selected category as first item and render
    final categories = List<Category>.from([category, ...subcategories]);
    return _renderListCategories(categories, selectedCategoryId, showImage);
  }

  /// Get the parent category ID for a given category ID
  /// This method handles both normal mode and large categories mode
  String? getParentCategories(String? id) {
    if (id == null) return null;

    // Try to get parent from local data first
    var parentId = _categoryModel.categories?.getParentByCategoryId(id);

    // If not found and large categories is enabled, search in cached subcategories
    if (parentId == null && kEnableLargeCategories) {
      for (var entry in _categoryModel.subOfCategory.entries) {
        // Check if any category in this subcategory list matches the ID
        final isParent = entry.value.any((category) => category.id == id);

        if (isParent) {
          // The key is the parent ID
          parentId = entry.key;
          break;
        }
      }
    }

    return parentId;
  }
}

class CategoryMenuDelegate {
  String? Function()? onGetIdCategoryParent;
}
