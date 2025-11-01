import '../../models/index.dart' show Product;

class ChatArguments {
  final String? receiverId;
  final String? receiverEmail;
  final String? receiverName;
  final Product? product;

  ChatArguments({
    required this.receiverId,
    required this.receiverEmail,
    required this.receiverName,
    this.product,
  });
}
