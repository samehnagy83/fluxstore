import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants.dart';
import '../../../../models/entities/filter_sorty_by.dart';
import '../../../../models/index.dart';
import '../../../app.dart';
import '../../../common/config.dart';
import '../../../common/tools/price_tools.dart';
import '../../../models/entities/filter_product_params.dart';
import '../../../modules/dynamic_layout/config/product_config.dart';
import '../../../services/service_config.dart';
import '../../../widgets/backdrop/filter.dart';
import '../../../widgets/common/drag_handler.dart';
import '../widgets/filter_label.dart';

part 'getter_extension.dart';
part 'methods_extension.dart';
part 'widget_extension.dart';

mixin ProductsFilterMixin<T extends StatefulWidget> on State<T> {
  FilterAttributeModel get filterAttrModel =>
      context.read<FilterAttributeModel>();

  CategoryModel get categoryModel => context.read<CategoryModel>();

  TagModel get tagModel => context.read<TagModel>();

  // We need to use [FilterBrandModel] not [BrandLayoutModel] here
  FilterBrandModel get brandModel => context.read<FilterBrandModel>();

  ProductPriceModel get productPriceModel => context.read<ProductPriceModel>();

  Future<void> getProductList({bool forceLoad = false});

  void clearProductList();

  /// Call setState(() {}) or notifyListener().
  void rebuild();

  void onCloseFilter();

  void onCategorySelected(String? name);

  void onClearTextSearch() {}

  /// Filter params.
  List<String>? _categoryIds;

  List<String>? get categoryIds => _categoryIds?.toList();

  final List<StackPathCategory> _stackSelectedCategory = [];

  List<StackPathCategory> get stackSelectedCategory => _stackSelectedCategory;

  /// Updates the category selection stack by building the complete hierarchical path
  /// from root to the selected category. This ensures proper navigation breadcrumbs
  /// and maintains the category tree structure for filtering operations.
  ///
  /// **Purpose:**
  /// - Builds a navigation path stack for hierarchical category filtering
  /// - Maintains category hierarchy for proper breadcrumb navigation
  /// - Ensures consistent state when users navigate through category levels
  ///
  /// **Algorithm Flow:**
  /// 1. **Level Check**: Validates category level and parent requirements
  /// 2. **Duplicate Prevention**: Avoids adding duplicate parent categories to the stack
  /// 3. **Stack Reconstruction**: Clears existing stack and rebuilds from scratch
  /// 4. **Level 1 Handling**: For first-level categories, adds single stack entry
  /// 5. **Deep Level Handling**: For deeper levels, traverses up the tree to build complete path
  ///
  /// **Parameters:**
  /// - `categoryId`: The ID of the currently selected category
  /// - `parentCategoryId`: The ID of the parent category (can be null for root categories)
  ///
  /// **Examples:**
  /// ```dart
  /// // Level 1 category selection (e.g., "Electronics")
  /// updateStack("electronics_123", "root_0");
  /// // Result: [StackPathCategory(categoryId: "electronics_123", level: 1)]
  ///
  /// // Level 3 category selection (e.g., "Smartphones" under "Electronics > Mobile")
  /// updateStack("smartphones_456", "mobile_234");
  /// // Result: [
  /// //   StackPathCategory(categoryId: "electronics_123", level: 1),
  /// //   StackPathCategory(categoryId: "mobile_234", level: 2),
  /// //   StackPathCategory(categoryId: "smartphones_456", level: 3)
  /// // ]
  /// ```
  void updateStack(String categoryId, String? parentCategoryId) {
    // **BLOCK 1: Level Validation and Early Exit Conditions**
    // Get the hierarchical level of the selected category (0=root, 1=first level, etc.)
    final level = categoryModel.getCategoryLevel(categoryId);

    // **BLOCK 1A: Early Exit for Root Categories**
    // Exit early if category is root level (level 0) or has no parent
    // Root categories don't need stack management as they are the starting point
    if (level == 0 || (parentCategoryId?.isEmpty ?? true)) {
      return;
    }

    // **BLOCK 2: Duplicate Prevention Check**
    // Check if the parent category already exists in the current stack
    // This prevents adding duplicate entries and maintains stack integrity
    if (_stackSelectedCategory.isNotEmpty) {
      // Search for parent category in the existing stack
      final indexParent = _stackSelectedCategory
          .indexWhere((e) => e.categoryId == parentCategoryId);

      // **BLOCK 2A: Exit if Parent Already Exists**
      // If parent category is already in stack, no need to rebuild
      // This avoids unnecessary stack reconstruction and maintains current state
      if (indexParent != -1) {
        return;
      }
    }

    // **BLOCK 3: Stack Reset and Reconstruction**
    // Clear the current stack to rebuild it from scratch with the new category path
    // This ensures a clean, consistent navigation hierarchy
    _stackSelectedCategory.clear();

    // **BLOCK 4: Level 1 Category Handling (Simple Case)**
    // Special handling for first-level categories that only need a single stack entry
    if (level == 1) {
      // **BLOCK 4A: Get Category Information**
      // Retrieve category details from the model for stack entry creation
      final category = categoryModel.categoryList[categoryId];

      // **BLOCK 4B: Add Single Level 1 Entry**
      // Create and add a single stack entry for the level 1 category
      // This is the simplest case as no parent traversal is needed
      _stackSelectedCategory.add(
        StackPathCategory(
          categoryId: categoryId,
          parentCategoryId: category?.parent,
          level: 1,
        ),
      );
    } else {
      // **BLOCK 5: Multi-Level Category Handling (Complex Case)**
      // Handle categories with level > 1 that require building a complete path

      // **BLOCK 5A: Initialize Tree Traversal**
      // Start from the current category and prepare to traverse upward
      String? currentCategoryId = categoryId;
      final list = <Category>[];

      // **BLOCK 5B: Traverse Up the Category Tree**
      // Build a complete path from the selected category up to the root
      // This creates the full hierarchical context needed for navigation
      while (currentCategoryId != null) {
        // Get category information from the model
        final category = categoryModel.categoryList[currentCategoryId];
        if (category != null) {
          // **BLOCK 5B1: Add Category to Path**
          // Insert at beginning to maintain order from root to leaf
          // This ensures the final list represents the correct hierarchy
          list.insert(0, category);

          // **BLOCK 5B2: Move to Parent**
          // Continue traversal by moving to the parent category
          currentCategoryId = category.parent;
        } else {
          // **BLOCK 5B3: Break on Missing Category**
          // Stop traversal if category is not found in the model
          break;
        }
      }

      // **BLOCK 5C: Build Level Map and Create Stack Entries**
      // Process the complete category path and create stack entries with correct levels
      final mapLevel = <String, int>{};

      // **BLOCK 5C1: Iterate Through Category Path**
      // Process each category in the path from root to selected category
      for (var i = 0; i < list.length; i++) {
        final category = list[i];

        // **BLOCK 5C2: Handle Root Categories**
        // Skip root categories but track their level for parent-child relationships
        if (category.isRoot) {
          mapLevel.addAll({category.id!: 0});
          continue;
        }

        // **BLOCK 5C3: Calculate and Assign Levels**
        // Determine the correct level based on parent's level
        final parentLevel = mapLevel[category.parent] ?? 0;

        // **BLOCK 5C4: Add to Navigation Stack**
        // Create stack entry with calculated level and add to navigation stack
        // This builds the complete breadcrumb path for the selected category
        _stackSelectedCategory.add(
          StackPathCategory(
            categoryId: category.id!,
            parentCategoryId: category.parent,
            level: parentLevel + 1,
          ),
        );
      }
    }
  }

  /// Toggles category selection and manages the navigation stack for hierarchical category filtering.
  /// This function handles both forward navigation (selecting categories) and backward navigation
  /// (going back through the category hierarchy).
  ///
  /// **Purpose:**
  /// - Manages category selection state in a hierarchical tree structure
  /// - Maintains navigation stack for breadcrumb-style category filtering
  /// - Handles both single and multi-level category navigation
  /// - Supports jump navigation to prevent level conflicts
  ///
  /// **Parameters:**
  /// - `categoryId`: ID of the category to toggle (null for backward navigation)
  /// - `parentCategoryId`: ID of the parent category
  /// - `hasChild`: Whether the selected category has child categories
  /// - `cleanStack`: Whether to clear the entire stack before processing
  /// - `jumpStep`: Prevents level 0 and 1 categories from coexisting in stack
  ///
  /// **Returns:** The ID of the currently selected category or null if none selected
  String? onToogleCategory({
    String? categoryId,
    String? parentCategoryId,
    bool hasChild = false,
    bool cleanStack = false,

    /// Handling a jump step means processing to ensure that category
    /// level 0 and 1 do not coexist on the stack. The category tree only
    /// comprises a single main category tree at any given time.
    /// This will cause backward navigation not to fully include all the
    /// categories the user has selected.
    bool jumpStep = false,
  }) {
    // **BLOCK 1: Forward Navigation - Category Selection**
    // This block handles when a user selects a specific category (categoryId is provided)
    if (categoryId?.isNotEmpty ?? false) {
      // Get the hierarchical level of the selected category (0=root, 1=first level, etc.)
      final level = categoryModel.getCategoryLevel(categoryId!);

      // **BLOCK 1A: Stack Cleanup**
      // Clear the entire navigation stack if requested (used for fresh starts)
      if (cleanStack) {
        _stackSelectedCategory.clear();
      }

      // **BLOCK 1B: Helper Functions Definition**
      // Local function to add a new category to the navigation stack
      void pushStack() {
        _stackSelectedCategory.add(
          StackPathCategory(
            categoryId: categoryId,
            parentCategoryId: parentCategoryId,
            level: level,
          ),
        );
      }

      // Local function to replace the last item in the stack with current category
      // Used when navigating within the same level or correcting selection
      void overrideLastItem() {
        final indexLast = _stackSelectedCategory.length - 1;
        if (indexLast >= 0) {
          _stackSelectedCategory[indexLast] = StackPathCategory(
            categoryId: categoryId,
            parentCategoryId: parentCategoryId,
            level: level,
          );
        }
      }

      // **BLOCK 1C: Get Current Stack State**
      // Retrieve the last selected category from the stack for comparison
      final lastItem = _stackSelectedCategory.isNotEmpty
          ? _stackSelectedCategory.last
          : null;

      // **BLOCK 1D: Jump Step Logic for Root Categories**
      // Special handling when jumpStep is enabled and selecting a root category (level 0)
      // Prevents conflicts between root and first-level categories in the same stack
      if (level == 0 && jumpStep) {
        final indexLevel0 =
            _stackSelectedCategory.indexWhere((e) => e.level == 0);

        // If a level 0 category already exists or stack is empty, clear and start fresh
        if (indexLevel0 >= 0 || _stackSelectedCategory.isEmpty) {
          _stackSelectedCategory.clear();
          return categoryId;
        }
      }

      // **BLOCK 1E: Empty Stack Handling**
      // Logic for when no categories are currently selected (first selection)
      if (lastItem == null) {
        if (jumpStep) {
          // In jump mode, always add to stack
          pushStack();
        } else {
          // In normal mode, clear stack for root categories, add to stack for others
          if (level == 0) {
            _stackSelectedCategory.clear();
          } else {
            pushStack();
          }
        }
      } else {
        // **BLOCK 1F: Existing Stack Handling**
        // Logic for when there are already selected categories in the stack

        // **BLOCK 1F1: Level 1 Category Special Handling**
        // When selecting a level 1 category, remove all existing level 1+ categories
        // to prevent multiple main category branches in the same stack
        if (level == 1) {
          final indexLevel1 =
              _stackSelectedCategory.indexWhere((e) => e.level == 1);
          if (indexLevel1 != -1) {
            if (indexLevel1 >= 0) {
              // Keep only categories before the first level 1 category
              var newlist = _stackSelectedCategory.sublist(0, indexLevel1);
              _stackSelectedCategory
                ..clear()
                ..addAll(newlist.toList());
            }
          }
        }

        // **BLOCK 1F2: Category Comparison Logic**
        // Compare the new selection with the current last item to determine action
        final isCategoryDiffLastItem =
            lastItem.isTheSameValue(categoryId) == false;
        final isParentDiffLastItem =
            lastItem.isTheSameValue(parentCategoryId) == false;
        final emptyParentCategory = parentCategoryId?.isEmpty ?? true;

        // **BLOCK 1F3: Decision Logic for Stack Modification**
        if (isCategoryDiffLastItem) {
          // New category is different from the last selected category
          if (emptyParentCategory) {
            // No parent category specified
            if (hasChild) {
              // Category has children - add to stack for potential drill-down
              pushStack();
            } else {
              // Leaf category - replace the last item
              overrideLastItem();
            }
          } else if (isParentDiffLastItem || hasChild) {
            // Different parent or has children - add to stack for navigation
            pushStack();
          } else {
            // Same parent, add to stack
            pushStack();
          }
        } else {
          // Same category as last item - just update the stack entry
          overrideLastItem();
        }
      }

      // Return the selected category ID
      return categoryId;
    } else if (_stackSelectedCategory.isNotEmpty) {
      // **BLOCK 2: Backward Navigation - Going Back Through Category Hierarchy**
      // This block handles when user wants to go back (categoryId is null but stack exists)

      String? idCtg;

      // **BLOCK 2A: Multi-Level Stack Handling**
      // When stack has 2 or more items, go back to the previous level
      if (_stackSelectedCategory.length >= 2) {
        // Get the second-to-last category (the one to go back to)
        idCtg = _stackSelectedCategory[_stackSelectedCategory.length - 2]
            .categoryId;
        // Remove the current (last) category from stack
        _stackSelectedCategory.removeLast();

        // Safety check - if stack becomes empty, return null
        if (_stackSelectedCategory.isEmpty) {
          return null;
        }
      } else {
        // **BLOCK 2B: Single Item Stack Handling**
        // When stack has only one item, decide how to handle based on jumpStep
        if (jumpStep == false) {
          // Normal mode: check if current category has subcategories
          final item = _stackSelectedCategory.first;
          final subCtg = categoryModel.getSubCategory(item.categoryId);
          _stackSelectedCategory.clear();
          // Return parent if subcategories exist, null otherwise
          return subCtg.isNotEmpty ? item.parentCategoryId : null;
        }

        // Jump mode: simply clear the stack
        _stackSelectedCategory.clear();
      }

      return idCtg;
    }

    // **BLOCK 3: Default Case**
    // No category selected and stack is empty - return null
    return null;
  }

  set categoryIds(List<String>? value) {
    _categoryIds = value?.toList();
  }

  double? minPrice;
  double? maxPrice;
  int page = 1;

  List<String>? _tagIds;

  List<String>? get tagIds => _tagIds?.toList();

  set tagIds(List<String>? value) {
    _tagIds = value?.toList();
  }

  String? listingLocationId;
  List? include;
  String? search;
  bool? isSearch;

  List<String>? _brandIds;

  List<String>? get brandIds => _brandIds?.toList();

  set brandIds(List<String>? value) {
    _brandIds = value?.toList();
  }

  /// List all selected sub attributes of each selected attribute
  Map<FilterAttribute, List<SubAttribute>> lstSelectedAttribute = {};

  void updateSelectedSubAttribute({
    required int attributeId,
    required SubAttribute subAttribute,
  }) {
    final attribute = filterAttrModel.lstProductAttribute
        ?.firstWhere((element) => element.id == attributeId);
    final subAttributes = lstSelectedAttribute[attribute];

    if (subAttributes?.indexWhere((element) => element.id == subAttribute.id) ==
        -1) {
      lstSelectedAttribute[attribute!] = [subAttribute];
    } else {
      lstSelectedAttribute[attribute]
          ?.removeWhere((element) => element.id == subAttribute.id);
    }
  }

  void resetAllSelectedAttribute() {
    lstSelectedAttribute.clear();
  }

  void onTapOpenFilter() {
    showFilterBottomSheet();
  }

  FilterSortBy filterSortBy = const FilterSortBy();

  bool get showLayout => true;

  bool get showSort => true;

  bool get showPriceSlider => true;

  bool get showCategory => true;

  bool get showAttribute => true;

  bool get showTag => true;

  bool get showBrand => true;

  bool get allowMultipleCategory => ServerConfig().allowMultipleCategory;

  bool get showTagCategoryImage => false;

  bool get allowMultipleTag => ServerConfig().allowMultipleTag;

  bool get allowGetTagByCategory =>
      ServerConfig().isWooPluginSupported &&
      kAdvanceConfig.allowGetDatasByCategoryFilter;

  bool get allowGetAttributeByCategory =>
      ServerConfig().isWooPluginSupported &&
      kAdvanceConfig.allowGetDatasByCategoryFilter;

  bool get allowGetBrandByCategory =>
      ServerConfig().isWooPluginSupported &&
      kAdvanceConfig.allowGetDatasByCategoryFilter;

  bool get allowMultiAttribute =>
      ServerConfig().isWooPluginSupported &&
      kAdvanceConfig.allowGetDatasByCategoryFilter;
}

class StackPathCategory {
  final String categoryId;
  final String? parentCategoryId;
  final int level;

  StackPathCategory({
    required this.categoryId,
    required this.level,
    this.parentCategoryId,
  });

  Map toJson() {
    return {
      'categoryId': categoryId,
      'parentCategoryId': parentCategoryId,
      'level': level,
    };
  }

  bool isTheSameValue(String? id) {
    return categoryId == id || parentCategoryId == id;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
