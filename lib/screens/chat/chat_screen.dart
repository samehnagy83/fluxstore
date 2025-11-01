import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/index.dart';
import '../../services/services.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    this.receiverEmail,
    this.receiverName,
    this.product,
  });

  final String? receiverEmail;
  final String? receiverName;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    var initMessage;
    if (product != null) {
      initMessage = product?.name ?? '';
      initMessage += '\n';
      initMessage += product?.permalink ?? '';
    }

    return Consumer<UserModel>(
      builder: (context, value, child) {
        final user = value.user;

        return Services().firebase.renderChatScreen(
              senderEmail: user?.email,
              senderName: user?.name,
              receiverEmail: receiverEmail,
              receiverName: receiverName,
              initMessage: initMessage,
            );
      },
    );
  }
}
