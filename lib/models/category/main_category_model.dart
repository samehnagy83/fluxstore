import '../../common/extensions/list_categories_extension.dart';
import '../../common/utils/category_utils.dart';
import '../entities/category.dart';
import 'category_model.dart';
import 'detail_category_model.dart';
import 'list_category_model.dart';

class MainCategoryModel extends ListCategoryModel implements CategoryModel {
  MainCategoryModel() : super(parentId: null, limit: 15);

  final Map<String, DetailCategoryModel> _subCategories = {};

  @override
  void initSubcategory(Category category, {bool fetchData = false}) {
    if (_subCategories[category.id] != null) {
      return;
    }
    final model = DetailCategoryModel(category: category);
    if (fetchData) {
      model.initData();
    }
    _subCategories[category.id!] = model;
  }

  @override
  DetailCategoryModel? getDetailCategoryModel(String id) {
    if (_subCategories.containsKey(id)) {
      return _subCategories[id];
    }
    return null;
  }

  /// All methods below support the BaseCategoryModel interface

  @override
  Future<void> getCategories({
    sortingList,
    categoryLayout,
    List<Map>? remapCategories,
  }) =>
      getData();

  @override
  List<Category>? getCategory({
    required String parentId,
  }) =>
      null;

  @override
  void mapCategories(
    List<Category> categories,
    List<Map> remapCategories,
  ) {}

  @override
  void sortCategoryList({
    List<Category>? categoryList,
    sortingList,
    String? categoryLayout,
  }) {}

  @override
  List<Category>? get categories => data;

  @override
  Map<String?, Category> get categoryList => Map.fromIterables(
      List.generate(data.length, (index) => data[index].id), data);

  /// Because the default MainCategoryModel just fetch root categories
  @override
  List<Category>? get rootCategories => categories;

  @override
  void refreshCategoryList() => refresh(autoGetData: false);

  @override
  String? getIdParentCategories(String id) =>
      categories.getParentByCategoryId(id);

  @override
  Map<String, List<Category>> subOfCategory = {};

  @override
  int getCategoryLevel(String categoryId) {
    return CategoryUtils.getCategoryLevel(
      categoryId,
      categories,
      subOfCategory: subOfCategory,
    );
  }

  @override
  Category? findRootCategory(String categoryId) {
    return CategoryUtils.findRootCategory(
      categoryId,
      categories: categories,
      subOfCategory: subOfCategory,
    );
  }

  @override
  Category? getCategoryById(String id) => CategoryUtils.findCategoryById(
        id,
        categories: categories,
        subOfCategory: subOfCategory,
      );

  @override
  List<Category> getSubCategory(String parentId) {
    /// Get subcategories from local data
    if (subOfCategory[parentId] != null) {
      return subOfCategory[parentId]!;
    }

    var ctg = categories ?? <Category>[];
    return ctg.where((o) => o.parent == parentId).toList();
  }
}
