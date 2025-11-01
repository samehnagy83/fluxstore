import 'dart:convert' as convert;
import 'dart:core';

import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:quiver/strings.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart'
    hide httpGet, httpPost, httpPut, httpPatch, httpDelete;
import '../../../common/extensions/string_ext.dart';
import '../../../models/entities/prediction.dart';
import '../../../models/index.dart' show Category, Product, Review, User;
import '../../../services/index.dart';
import '../../../services/location_service.dart';
import '../../woocommerce/services/woo_commerce.dart';
import 'wcfm_connector.dart';

class WCFMService extends WooCommerceService {
  final WCFMConnector wcfmConnector;

  String? jwtToken;

  WCFMService({
    required super.domain,
    super.blogDomain,
    required super.consumerKey,
    required super.consumerSecret,
  }) : wcfmConnector = WCFMConnector(domain);

  @override
  Future<User?> createUser({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? password,
    String? phoneNumber,
    bool isVendor = false,
    bool isDelivery = false,
    bool isOwner = false,
  }) async {
    try {
      var niceName = '${firstName!} ${lastName!}';
      var endPoint =
          '$domain/wp-json/api/flutter_user/sign_up/?insecure=cool&$isSecure'
              .toUri()!;

      var data = {
        'user_email': email ?? username,
        'user_login': username ?? email,
        'username': username ?? email,
        'first_name': firstName,
        'last_name': lastName,
        'user_pass': password,
        'email': email ?? username,
        'user_nicename': niceName,
        'display_name': niceName,
        'phone': phoneNumber,
      };

      var role = 'subscriber';
      if (isVendor) {
        role = 'wcfm_vendor';
        if (!kVendorConfig.enableAutoApplicationApproval) {
          role = 'subscriber';
          data['wcfm_membership_application_status'] = 'pending';
        }
      }
      if (isDelivery) {
        role = 'wcfm_delivery_boy';
      }

      data['role'] = role;

      final response = await wcfmConnector.httpPost(endPoint,
          body: convert.jsonEncode(data),
          headers: {'Content-Type': 'application/json'});
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && body['message'] == null) {
        var cookie = body['cookie'];
        return await getUserInfo(cookie);
      }
      if (body is Map && isNotBlank(body['message'])) {
        if (body['code'] == 'invalid_username') {
          throw Exception(S.current.usernameInvalid);
        }
        if (body['code'] == 'existed_username') {
          throw Exception(S.current.usernameAlreadyInUse);
        }
        if (body['code'] == 'invalid_email') {
          throw Exception(S.current.emailAddressInvalid);
        }
        if (body['code'] == 'existed_email') {
          throw Exception(S.current.emailAlreadyInUse);
        }
        throw Exception(body['message']);
      }
    } catch (err) {
      printLog(err);
      rethrow;
    }
    return null;
  }

  @override
  Future<List<Product>>? getProductsByStore({
    storeId,
    int? page,
    int? perPage,
    int? catId,
    bool? onSale,
    String? order,
    String? orderBy,
    String? searchTerm,
  }) async {
    var list = <Product>[];
    try {
      var endpoint =
          '$domain/wp-json/api/flutter_multi_vendor/products/owner?id=$storeId';

      endpoint = endpoint
          .addUrlQuery('is_all_data=${kAdvanceConfig.enableIsAllData == true}');

      if (page == null || perPage == null) {
        page = 1;
        perPage = 10;
      }
      endpoint += '&page=$page&per_page=$perPage';
      if (catId != null && catId != -1) {
        endpoint += '&category=$catId';
      }
      if (searchTerm != null && searchTerm.trim().isNotEmpty) {
        endpoint += '&search=$searchTerm';
      }
      if (onSale != null && onSale) {
        endpoint += '&on_sale=true';
      }
      if (order != null && orderBy != null) {
        endpoint += '&order=$order&orderby=$orderBy';
      }
      if (kAdvanceConfig.isMultiLanguages) {
        endpoint += '&lang=$languageCode';
      }
      if (kExcludedProductIDs?.isNotEmpty ?? false) {
        endpoint += '&exclude=$kExcludedProductIDs';
      }

      final response = await wcfmConnector.httpGet(endpoint.toUri()!);
      var result = convert.jsonDecode(response.body);

      var products = productsFromJsonData(result);
      if (products != null) {
        list.addAll(products);
      }
    } catch (e) {
      printLog(e);
    }
    return list;
  }

  @override
  Future<List<Review>> getReviewsStore(
      {storeId, page = 1, perPage = 10}) async {
    var list = <Review>[];
    try {
      var response = await wcfmConnector.httpGet(
        '$domain/wp-json/api/flutter_multi_vendor/get-reviews?store_id=$storeId&page=$page&per_page=$perPage&status_type=approved'
            .toUri()!,
      );
      var result = convert.jsonDecode(response.body);

      for (var item in result) {
        if (int.parse(item['vendor_id']) == storeId) {
          list.add(Review.fromWCFMJson(item));
        }
      }
    } catch (e) {
      printLog(e);
    }
    return list;
  }

  @override
  Future<Store?> getStoreInfo(storeId) async {
    try {
      var response = await wcConnector.getAsync('flutter/wcfm-stores/$storeId');

      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        if (response['settings'] == null) {
          return null;
        }
        return Store.fromWCFMJson(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Store>> searchStores({String? keyword, int? page}) async {
    try {
      var list = <Store>[];
      var endPoint = 'flutter/wcfm-stores?page=${page ?? 1}&per_page=20';
      if (keyword?.isNotEmpty ?? false) {
        endPoint = endPoint.addUrlQuery('search=$keyword');
      }
      if (kAdvanceConfig.filterProductsByDistance) {
        endPoint = await _addFilterProductsByDistance(endPoint);
      }
      final response = await wcConnector.getAsync(endPoint);
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(Store.fromWCFMJson(item));
        }
        return list;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Store>>? getFeaturedStores({
    int? page,
    int? perPage,
  }) async {
    var list = <Store>[];
    var endPoint =
        'flutter/wcfm-stores?page=${page ?? 1}&per_page=${perPage ?? 100}';
    try {
      if (kAdvanceConfig.filterProductsByDistance) {
        endPoint = await _addFilterProductsByDistance(endPoint);
      }
      final response = await wcConnector.getAsync(
        endPoint,
      );
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      }
      if (response is List && response.isNotEmpty) {
        for (var item in response) {
          if (!item['disable_vendor']) list.add(Store.fromWCFMJson(item));
        }
      }
      return list;
    } catch (err, stack) {
      printError(err, stack);
    }
    return list;
  }

  @override
  Future<List<Store>> getNearbyStores({
    Prediction? prediction,
    int page = 1,
    int perPage = 10,
    int radius = 10,
    String? name,
  }) async {
    var list = <Store>[];

    try {
      var endpoint = 'flutter/wcfm-stores?page=$page&per_page=$perPage';
      endpoint = _addRangeQuery(
        endPoint: endpoint,
        latitude: num.tryParse('${prediction?.lat}'),
        longitude: num.tryParse('${prediction?.long}'),
        range: radius,
      );
      if (name != null && name.trim().isNotEmpty) {
        endpoint += '&search=$name';
      }
      final response = await wcConnector.getAsync(endpoint);
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      }
      if (response is List && response.isNotEmpty) {
        for (var item in response) {
          if (!item['disable_vendor']) {
            final store = Store.fromWCFMJson(item);
            if (store.lat == null || store.long == null) {
              continue;
            }
            list.add(Store.fromWCFMJson(item));
          }
        }
      }
      return list;
    } catch (e) {
      printLog(e);
    }
    return list;
  }

  @override
  Future<List<Category>> getCategoriesByPage({
    page,
    limit,
    storeId,
    String? searchTerm,
    int? parent,
    bool useCompute = true,
    dynamic nextCursor,
  }) async {
    var list = <Category>[];
    try {
      var endpoint =
          '$domain/wp-json/api/flutter_multi_vendor/product-categories';
      const perPage = 100;
      page ??= 1;
      endpoint += '?page=$page&limit=$perPage';
      if (storeId != null) {
        endpoint += '&id=$storeId';
      }
      if (kAdvanceConfig.isMultiLanguages) {
        endpoint += '&lang=$languageCode';
      }
      if (kAdvanceConfig.hideEmptyCategories) {
        endpoint += '&hide_empty=true';
      }
      if (kExcludedCategoryIDs?.isNotEmpty ?? false) {
        endpoint += '&exclude=$kExcludedCategoryIDs';
      }
      final response = await wcfmConnector.httpGet(endpoint.toUri()!);
      var result = convert.jsonDecode(response.body);
      for (var item in result) {
        final cat = Category.fromJson(item);
        if (cat.id != null) {
          list.add(cat);
        }
      }
    } catch (e) {
      printLog(e);
    }
    return list;
  }

  @override
  Future<Store?> getStoreByPermalink(String storePermaLink) async {
    try {
      final response = await wcfmConnector.httpGet(
          '$domain/wp-json/wc/v2/flutter/vendor/dynamic?url=$storePermaLink'
              .toUri()!);

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Store.fromWCFMJson(body);
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://support.inspireui.com/help-center/
      rethrow;
    }
  }

  @override
  Future<VacationSettings?> getVacationSettings(String storeId) async {
    try {
      final response = await wcfmConnector.httpGet(
          '$domain/wp-json/wc/v2/flutter/vendor/vacation?store_id=$storeId'
              .toUri()!,
          refreshCache: true);

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return VacationSettings.fromJson(body);
      }
    } catch (e) {
      printLog(e);
    }
    return null;
  }

  @override
  Future<bool?> setVacationSettings(
      String cookie, VacationSettings vacationSettings) async {
    try {
      var data = vacationSettings.toJson();
      data['cookie'] = cookie;
      final response = await wcfmConnector.httpPost(
          '$domain/wp-json/wc/v2/flutter/vendor/vacation'.toUri()!,
          body: data);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      printLog(e);
    }
    return false;
  }

  @override
  Future getWooProductsResponse({
    String params = '',
    bool refreshCache = false,
    int version = 2,
  }) async {
    if (kAdvanceConfig.filterProductsByDistance) {
      final locationService = injector<LocationService>();
      await locationService.awaiting();

      final location = locationService.locationData;
      final enable = location?.longitude != null && location?.latitude != null;
      if (enable) {
        final range = kAdvanceConfig.maxQueryRadiusDistance;
        var advancedParams = _addRangeQuery(
          endPoint: params,
          latitude: location?.latitude,
          longitude: location?.longitude,
          range: range,
        );
        final endPoint = 'flutter/wcfm-products$advancedParams';
        // The WCFM API only supports version 2
        final response = await wcConnector.getAsync(
          endPoint,
          refreshCache: refreshCache,
          version: 2,
        );
        return response;
      }
    }

    return await super.getWooProductsResponse(
      params: params,
      refreshCache: refreshCache,
      version: version,
    );
  }

  @override
  Future<Map<String, dynamic>?> getHomeCache(String? lang) async {
    if (kAdvanceConfig.filterProductsByDistance) {
      var endPoint = buildUrlByLang('flutter/cache', isForceUseLang: true);
      endPoint = await _addFilterProductsByDistance(endPoint);
      final data = await wcConnector.getAsync(endPoint, refreshCache: true);
      if (data == null || data is! Map) {
        throw Exception("Can't get home cache");
      }
      if (data['message'] != null) {
        throw Exception(data['message']);
      }
      return Map<String, dynamic>.from(data);
    }
    return super.getHomeCache(lang);
  }

  Future<String> _addFilterProductsByDistance(String endPoint) async {
    final locationService = injector<LocationService>();
    await locationService.awaiting();
    final location = locationService.locationData;
    final enable = location?.longitude != null && location?.latitude != null;
    if (enable) {
      final range = kAdvanceConfig.maxQueryRadiusDistance;
      endPoint = _addRangeQuery(
        endPoint: endPoint,
        latitude: location?.latitude,
        longitude: location?.longitude,
        range: range,
      );
    }
    return endPoint;
  }

  String _addRangeQuery({
    required String endPoint,
    required num? latitude,
    required num? longitude,
    required num? range,
  }) {
    var advancedParams = endPoint.addUrlQuery('wcfmmp_radius_lat=$latitude');
    advancedParams += '&wcfmmp_radius_lng=$longitude';
    advancedParams += '&wcfmmp_radius_range=$range';
    return advancedParams;
  }
}
