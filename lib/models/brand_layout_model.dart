import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../common/enums/load_state.dart';
import '../services/index.dart';
import 'entities/brand.dart';

/// Use `BrandLayoutModel` for Brand layout, Brand List and product detail
/// screen, not filter screen.
class BrandLayoutModel extends ChangeNotifier {
  final _services = Services();
  final List<Brand> _brands = [];

  List<Brand> get brands => _brands;

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

  Future<void> getBrands() async {
    try {
      if (_state == FSLoadState.loading) {
        return;
      }
      _updateState(FSLoadState.loading);
      _page = 1;
      _brands.clear();

      final list = await _services.api.getBrands(
            page: _page,
            perPage: _perPage,
          ) ??
          [];

      _brands.merge(list);

      _isEnded = list.isEmpty;
      _updateState(
          list.isNotEmpty ? FSLoadState.loaded : FSLoadState.noMoreData);
    } catch (e) {
      _updateState(FSLoadState.noData);
    }
  }

  Future<List<Brand>> loadMoreBrands() async {
    try {
      if (_state == FSLoadState.noMoreData) {
        return [];
      }
      _updateState(FSLoadState.loading);
      _page++;
      final list = await _services.api.getBrands(
            page: _page,
            perPage: _perPage,
          ) ??
          [];

      _brands.merge(list);
      _isEnded = list.isEmpty;
      _updateState(
          list.isNotEmpty ? FSLoadState.loaded : FSLoadState.noMoreData);

      return list;
    } catch (e) {
      _updateState(FSLoadState.noData);
      return [];
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
