import 'package:flux_ui/flux_ui.dart';

import '../../common/constants.dart';

class Review {
  int? id;
  int? productId;
  String productName = '';
  String? name;
  String? email;
  String? review;
  String? title;
  double? rating;
  late DateTime createdAt;
  String? avatar;
  String? status;
  int? isApproved;
  List<String> images = [];
  bool verified = false;

  Review({
    this.id,
    this.productId,
    this.productName = '',
    this.name,
    this.email,
    this.review,
    this.title,
    this.rating,
    required this.createdAt,
    this.avatar,
    this.status,
    this.isApproved,
    required this.images,
  });

  Review.fromJson(Map parsedJson) {
    id = parsedJson['id'];
    name = parsedJson['reviewer'];
    email = parsedJson['email'];
    review = parsedJson['review'];
    rating = double.tryParse('${parsedJson['rating']}');
    verified = parsedJson['verified'] ?? false;
    createdAt =
        DateTime.tryParse('${parsedJson['date_created']}') ?? DateTime.now();
    if (parsedJson['images'] is List) {
      for (var item in parsedJson['images']) {
        if (item is String && item.isURL) {
          images.add(item);
        }
      }
    }
    productName = parsedJson['product_name'] ?? '';
    productId = parsedJson['product_id'];
  }

  Review.fromOpencartJson(Map parsedJson) {
    id = parsedJson['review_id'] != null
        ? int.parse(parsedJson['review_id'])
        : 0;
    name = parsedJson['author'];
    email = parsedJson['author'];
    review = parsedJson['text'];
    rating = double.tryParse('${parsedJson['rating']}') ?? 0.0;
    createdAt =
        DateTime.tryParse('${parsedJson['date_added']}') ?? DateTime.now();
  }

  Review.fromMagentoJson(Map parsedJson) {
    id = parsedJson['id'];
    name = parsedJson['name'];
    email = parsedJson['email'];
    review = parsedJson['review'];
    rating = parsedJson['rating'];
    createdAt =
        DateTime.tryParse('${parsedJson['date_created']}') ?? DateTime.now();
  }

  Review.fromWCFMJson(Map parsedJson) {
    id = int.parse(parsedJson['ID']);
    name = parsedJson['author_name'];
    email = parsedJson['author_email'];
    review = Tools.removeHTMLTags(parsedJson['review_description']);
    avatar = parsedJson['author_image'];
    rating = double.tryParse('${parsedJson['review_rating']}');
    createdAt = DateTime.tryParse('${parsedJson['created']}') ?? DateTime.now();
    isApproved = int.parse(parsedJson['approved'] ?? '0');
  }

  Review.fromDokanJson(Map parsedJson) {
    id = parsedJson['id'];

    final author = parsedJson['author'];
    if (author is Map) {
      name = author['name'];
      email = author['email'];
      avatar = author['avatar'];
    }
    review = parsedJson['content'];
    rating = double.tryParse('${parsedJson['rating']}');
    createdAt = DateTime.tryParse('${parsedJson['date']}') ?? DateTime.now();
  }

  Review.fromListing(Map parsedJson) {
    try {
      id = int.tryParse('${parsedJson['id']}');

      name = parsedJson['author_name'] ?? '';

      email = parsedJson['author_email'] ?? '';

      final rawContent = parsedJson['content'];
      if (rawContent is Map) {
        review = rawContent['rendered'] ?? '';
      } else if (rawContent is String) {
        review = rawContent;
      }

      final rawTitle = parsedJson['title'];
      if (rawTitle is Map) {
        title = rawTitle['rendered'] ?? '';
      } else if (rawTitle is String) {
        title = rawTitle;
      }

      rating = double.tryParse('${parsedJson['rating']}') ?? 0.0;

      if (parsedJson['gallery_images'] is List) {
        for (var item in parsedJson['gallery_images']) {
          if (item is String && item.isURL) {
            images.add(item);
          }
        }
      }

      createdAt = DateTime.tryParse('${parsedJson['date']}') ?? DateTime.now();

      status = parsedJson['status'] ?? 'approved';

      avatar = parsedJson['author_avatar'];
    } catch (err) {
      printLog('FluxListing Review $err');
    }
  }

  String get displayName => name ?? 'Anonymous';

  String get displayContent => review ?? '';

  @override
  String toString() => 'Review { id: $id  name: $name}';
}
