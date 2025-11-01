import 'dart:convert' as convert;
import 'dart:core';

import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:quiver/strings.dart' show isNotBlank;

import '../../../common/config.dart';
import '../../../common/constants.dart'
    hide httpGet, httpPost, httpPut, httpPatch, httpDelete;
import '../../../common/extensions/string_ext.dart';
import '../../../models/entities/paging_response.dart';
import '../../../models/entities/prediction.dart';
import '../../../models/index.dart' show Category, Order, Product, Review, User;
import '../../woocommerce/services/woo_commerce.dart';
import 'dokan_connector.dart';

class DokanService extends WooCommerceService {
  DokanService({
    required super.domain,
    super.blogDomain,
    required super.consumerKey,
    required super.consumerSecret,
  }) : dokanConnector = DokanConnector(domain);

  final DokanConnector dokanConnector;

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
        role = 'seller';
        data['dokan_enable_selling'] =
            kVendorConfig.enableAutoApplicationApproval ? 'yes' : 'no';
      }
      if (isDelivery) {
        role = 'driver';
      }
      if (isOwner) {
        role = 'owner';
      }

      data['role'] = role;

      final response = await dokanConnector.httpPost(endPoint,
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
  Future<List<Store>>? getFeaturedStores({
    int? page,
    int? perPage,
  }) async {
    var list = <Store>[];
    try {
      var response = await dokanConnector
          .getAsync('stores?page=${page ?? 1}&per_page=${perPage ?? 100}');
      if (response.length == 0) {
        return list;
      }
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          if (item['featured']) list.add(Store.fromDokanJson(item));
        }
      }
    } catch (err, stack) {
      printError(err, stack);
    }
    return list;
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
      if (page == null || perPage == null) {
        page = 1;
        perPage = 10;
      }
      endpoint += '&page=$page&per_page=$perPage';

      endpoint = endpoint
          .addUrlQuery('is_all_data=${kAdvanceConfig.enableIsAllData == true}');

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

      final response = await dokanConnector.httpGet(endpoint.toUri()!);
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
      {storeId, page = 1, perPage = 100}) async {
    try {
      var list = <Review>[];
      var response = await dokanConnector.getAsync('stores/$storeId/reviews');

      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(Review.fromDokanJson(item));
        }
        return list;
      }
    } catch (e) {
      return <Review>[];
    }
  }

  @override
  Future<Store> getStoreInfo(storeId) async {
    try {
      var response = await dokanConnector.getAsync('stores/$storeId');

      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        return Store.fromDokanJson(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future? getJWTToken() {
    return null;
  }

  @override
  Future<List<Store>> searchStores({String? keyword, int? page}) async {
    try {
      var list = <Store>[];
      var endPoint = 'stores?';
      if (keyword?.isNotEmpty ?? false) {
        endPoint += 'search=$keyword';
      }

      endPoint += '&page=$page';
      endPoint += '&per_page=20';

      var response = await dokanConnector.getAsync(endPoint);

      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          if (item['enabled'] == true) {
            list.add(Store.fromDokanJson(item));
          }
        }
        return list;
      }
    } catch (e) {
      rethrow;
    }
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
      var endPoint =
          'flutter/get-nearby-stores?page=$page&per_page=$perPage&distance=$radius';
      if (prediction != null) {
        endPoint += '&latitude=${prediction.lat}&longitude=${prediction.long}';
      }
      if (name != null && name.trim().isNotEmpty) {
        endPoint += '&search=$name';
      }
      var response = await wcConnector.getAsync(endPoint);

      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else if (response is List) {
        for (var item in response) {
          var store = Store.fromDokanJson(item);
          if (store.lat != null && store.long != null) {
            list.add(store);
          }
        }
      }
      return list;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PagingResponse<Order>> getMyOrders({
    User? user,
    dynamic cursor,
    String? cartId,
    String? orderStatus,
  }) async {
    try {
      /// To remove dokan sub orders from result
      var endPoint =
          'orders?customer=${user!.id}&per_page=20&page=$cursor&order=desc&orderby=id&parent=0&dummy=${DateTime.now().millisecondsSinceEpoch}';
      if (orderStatus?.isNotEmpty ?? false) {
        endPoint += '&status=$orderStatus';
      }
      var response = await wcConnector.getAsync(endPoint, version: 3);
      var list = <Order>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(Order.fromJson(item));
        }
        return PagingResponse(data: list);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://support.inspireui.com/help-center/
      rethrow;
    }
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
      endpoint += '?page=$page&limit=$perPage&platform=dokan';
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
      final response = await dokanConnector.httpGet(endpoint.toUri()!);
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
      final response = await dokanConnector.httpGet(
          '$domain/wp-json/wc/v2/flutter/vendor/dynamic?url=$storePermaLink'
              .toUri()!);

      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200) {
        return Store.fromDokanJson(body);
      } else if (body['message'] != null) {
        throw Exception(body['message']);
      }
      return null;
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://support.inspireui.com/help-center/
      rethrow;
    }
  }
}
