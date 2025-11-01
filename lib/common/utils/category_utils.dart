import '../../models/entities/category.dart';

/// Utility class for category-related operations
class CategoryUtils {
  /// Get the level (depth) of a category based on its ID
  ///
  /// Parameters:
  /// - [categoryId]: ID of the category to find level for
  /// - [categories]: Main list of categories
  /// - [subOfCategory]: Map of subcategories (optional)
  ///
  /// Returns:
  /// - 0 for root categories
  /// - 1 for first level subcategories
  /// - 2 for second level subcategories, etc.
  /// - 0 if category is not found
  static int getCategoryLevel(
    String categoryId,
    List<Category>? categories, {
    Map<String, List<Category>>? subOfCategory,
  }) {
    // Track visited categories to prevent infinite loops
    final visited = <String>{};

    return _getCategoryLevelRecursive(
      categoryId,
      categories,
      visited,
      subOfCategory: subOfCategory,
    );
  }

  /// Find the root category of a given category
  ///
  /// Parameters:
  /// - [categoryId]: ID of the category to find root for
  /// - [categories]: Main list of categories
  /// - [subOfCategory]: Map of subcategories (optional)
  ///
  /// Returns:
  /// - The root Category if found
  /// - null if category is not found or circular reference detected
  static Category? findRootCategory(
    String categoryId, {
    List<Category>? categories,
    Map<String, List<Category>>? subOfCategory,
  }) {
    // Track visited categories to prevent infinite loops
    final visited = <String>{};

    return _findRootCategoryRecursive(
      categoryId,
      categories,
      visited,
      subOfCategory: subOfCategory,
    );
  }

  /// Recursive helper method to find root category
  static Category? _findRootCategoryRecursive(
    String categoryId,
    List<Category>? categories,
    Set<String> visited, {
    Map<String, List<Category>>? subOfCategory,
  }) {
    // Prevent circular reference
    if (visited.contains(categoryId)) {
      return null;
    }

    // Find category by ID
    final category = _findCategoryById(
      categoryId,
      categories,
      subOfCategory: subOfCategory,
    );

    if (category == null) {
      return null; // Category not found
    }

    // Check if this is a root category
    if (category.isRoot ||
        category.parent == null ||
        category.parent == '0' ||
        category.parent == '-1' ||
        category.parent!.isEmpty) {
      return category; // This is the root category
    }

    // Add current category to visited set before checking parent
    visited.add(categoryId);

    // Check if parent would create circular reference
    if (visited.contains(category.parent!)) {
      return category; // Return current category to avoid infinite loop
    }

    // Recursively find root category through parent
    return _findRootCategoryRecursive(
      category.parent!,
      categories,
      visited,
      subOfCategory: subOfCategory,
    );
  }

  /// Recursive helper method to calculate category level
  static int _getCategoryLevelRecursive(
    String categoryId,
    List<Category>? categories,
    Set<String> visited, {
    Map<String, List<Category>>? subOfCategory,
  }) {
    // Prevent circular reference
    if (visited.contains(categoryId)) {
      return 0;
    }

    // Find category by ID
    final category = _findCategoryById(
      categoryId,
      categories,
      subOfCategory: subOfCategory,
    );

    if (category == null) {
      return 0; // Category not found
    }

    // Check if this is a root category
    if (category.isRoot ||
        category.parent == null ||
        category.parent == '0' ||
        category.parent == '-1' ||
        category.parent!.isEmpty) {
      return 0;
    }

    // Add current category to visited set before checking parent
    visited.add(categoryId);

    // Check if parent would create circular reference
    if (visited.contains(category.parent!)) {
      return 0;
    }

    // Recursively find parent level and add 1
    return 1 +
        _getCategoryLevelRecursive(
          category.parent!,
          categories,
          visited,
          subOfCategory: subOfCategory,
        );
  }

  /// Helper method to find category by ID in categories list and subOfCategory map
  static Category? _findCategoryById(
    String categoryId,
    List<Category>? categories, {
    Map<String, List<Category>>? subOfCategory,
  }) {
    // Search in main categories list
    if (categories != null) {
      for (var category in categories) {
        if (category.id == categoryId) {
          return category;
        }
      }
    }

    // Search in subOfCategory map if provided
    if (subOfCategory != null) {
      for (var subcategoryList in subOfCategory.values) {
        for (var category in subcategoryList) {
          if (category.id == categoryId) {
            return category;
          }
        }
      }
    }

    return null;
  }

  /// Find category by ID from categories list and categoryList map
  ///
  /// Parameters:
  /// - [categoryId]: ID of the category to find
  /// - [categories]: Main list of categories
  /// - [categoryList]: Map of categories by ID (optional)
  /// - [subOfCategory]: Map of subcategories (optional)
  ///
  /// Returns the found Category or null if not found
  static Category? findCategoryById(
    String categoryId, {
    List<Category>? categories,
    Map<String?, Category>? categoryList,
    Map<String, List<Category>>? subOfCategory,
  }) {
    // First, search in categoryList map if provided
    if (categoryList != null && categoryList.containsKey(categoryId)) {
      return categoryList[categoryId];
    }

    // Then search using the private helper method
    return _findCategoryById(
      categoryId,
      categories,
      subOfCategory: subOfCategory,
    );
  }
}
