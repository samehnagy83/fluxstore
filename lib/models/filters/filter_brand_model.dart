import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../../common/enums/load_state.dart';
import '../../services/index.dart';
import '../entities/brand.dart';

class FilterBrandModel extends ChangeNotifier {
  final _services = Services();
  final List<Brand> _brands = [];

  Iterable<Brand> get listVisibleBrand =>
      _brands.where((element) => element.isVisible);

  // To get brands based on category
  List<String>? _categoryIds;

  FSLoadState _state = FSLoadState.loaded;

  FSLoadState get state => _state;
  bool get isEnded => _isEnded;
  bool _isDisposed = false;
  var _page = 1;
  final _perPage = 20;
  bool _isEnded = true;

  void _updateState(state) {
    _state = state;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Brand? getBrandById(String brandId) {
    return _brands.firstWhereOrNull((element) => element.id == brandId);
  }

  void addBrand(Brand brand) {
    final findBrand = getBrandById(brand.id);
    if (findBrand == null) {
      _brands.add(brand);
    }
  }

  Future<void> getBrands({
    List<String>? categoryIds,
    Function()? callback,
  }) async {
    try {
      if (_state == FSLoadState.loading) {
        return;
      }
      // Do not refresh the brand list if the dependent category list does not
      // change. This will help reduce server load. And keep the current brand
      // list for selected brands
      if (_brands.isNotEmpty && _compareTwoList(_categoryIds, categoryIds)) {
        return;
      }
      _categoryIds = categoryIds;
      _updateState(FSLoadState.loading);
      _page = 1;
      _brands.clear();

      final list = await _services.api.getBrands(
            page: _page,
            perPage: _perPage,
            categoryIds: _categoryIds,
          ) ??
          [];

      _brands.merge(list);

      _isEnded = list.isEmpty;
      callback?.call();
      _updateState(
          list.isNotEmpty ? FSLoadState.loaded : FSLoadState.noMoreData);
    } catch (e) {
      _updateState(FSLoadState.noData);
    }
  }

  Future<void> loadMoreBrands() async {
    try {
      if (_state == FSLoadState.noMoreData) {
        return;
      }
      _updateState(FSLoadState.loading);
      _page++;
      final list = await _services.api.getBrands(
            page: _page,
            perPage: _perPage,
            categoryIds: _categoryIds,
          ) ??
          [];

      _brands.merge(list);
      _isEnded = list.isEmpty;

      // Load until at least 1 item is visible or no more items
      final listVisibleBrand = list.where((element) => element.isVisible);
      if (list.isNotEmpty && listVisibleBrand.isEmpty) {
        return loadMoreBrands();
      }

      _updateState(
          list.isNotEmpty ? FSLoadState.loaded : FSLoadState.noMoreData);
    } catch (e) {
      _updateState(FSLoadState.noData);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool _compareTwoList(List<String>? firstList, List<String>? secondList) {
    final firstSortedList = (firstList ?? []).toList();
    firstSortedList.sort();
    final secondSortedList = (secondList ?? []).toList();
    secondSortedList.sort();
    if (firstSortedList.isEmpty && secondSortedList.isEmpty) {
      return true;
    }

    final firstFlatList = firstSortedList.join(',');
    final secondFlatList = secondSortedList.join(',');

    return firstFlatList == secondFlatList;
  }
}
