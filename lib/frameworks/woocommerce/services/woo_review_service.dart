import 'dart:convert';

import 'package:quiver/strings.dart';

import '../../../common/constants.dart';
import '../../../models/entities/paging_response.dart';
import '../../../models/entities/rating_count.dart';
import '../../../models/entities/review.dart';
import '../../../models/entities/review_payload.dart';
import '../../../services/review_service.dart';
import 'woo_commerce.dart';
import 'woo_connector.dart';

final class WooReviewService extends ReviewService {
  final WooComerceConnector wcConnector;

  const WooReviewService(this.wcConnector);

  @override
  Future<void> createReview(ReviewPayload payload) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
      };
      final token = payload.token;
      if (token != null) {
        headers['User-Cookie'] = EncodeUtils.encodeCookie(token);
      }

      final response = await wcConnector.httpPost(
        '${wcConnector.url}/wp-json/api/flutter_woo/products/reviews'.toUri()!,
        body: jsonEncode(payload.toWooJson()),
        headers: headers,
      );
      var body = jsonDecode(response.body);
      checkExpiredCookie(response);
      if (body['message'] == null) {
        return;
      } else {
        throw Exception(body['message']);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://support.inspireui.com/help-center/
      rethrow;
    }
  }

  @override
  Future<PagingResponse<Review>> getReviews(
    productId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var response = await wcConnector.getAsync(
        'products/reviews?per_page=$perPage&page=$page&product=$productId',
        version: 3,
      );
      var list = <Review>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else {
        for (var item in response) {
          list.add(Review.fromJson(item));
        }
        return PagingResponse(data: list);
      }
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://support.inspireui.com/help-center/
      rethrow;
    }
  }

  @override
  Future<RatingCount?> getProductRatingCount(String productId) async {
    try {
      final response = await wcConnector.httpGet(
          '${wcConnector.url}/wp-json/api/flutter_woo/products/$productId/rating_counts'
              .toUri()!);

      var json = jsonDecode(response.body);

      if (json is Map && isNotBlank(json['message'])) {
        throw Exception(json['message']);
      } else {
        return RatingCount.fromJson(json);
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<PagingResponse<Review>> getListReviewByUserEmail(
    String email, {
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      var endpoint =
          'products/reviews?per_page=$perPage&page=$page&reviewer_email=$email';
      if (status != null) {
        endpoint += '&status=$status';
      }
      var response = await wcConnector.getAsync(
        endpoint,
        version: 3,
      );
      var list = <Review>[];
      if (response is Map && isNotBlank(response['message'])) {
        throw Exception(response['message']);
      } else if (response is List) {
        for (var item in response) {
          list.add(Review.fromJson(item));
        }
        return PagingResponse(data: list, cursor: page);
      }

      return PagingResponse(data: list, cursor: page);
    } catch (e) {
      //This error exception is about your Rest API is not config correctly so that not return the correct JSON format, please double check the document from this link https://support.inspireui.com/help-center/
      rethrow;
    }
  }
}
