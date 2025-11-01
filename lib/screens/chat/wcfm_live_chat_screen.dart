import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/index.dart';
import '../../services/services.dart';

class WcfmLiveChatScreen extends StatelessWidget {
  const WcfmLiveChatScreen({
    super.key,
    this.receiverId,
    this.receiverEmail,
    this.receiverName,
    this.product,
  });

  final String? receiverId;
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
      builder: (context, userModel, child) {
        final user = userModel.user;

        return Services().firebase.renderWcfmLiveChatScreen(
              senderId: user?.id,
              senderName: user?.name,
              senderEmail: user?.email,
              senderIsVendor: user?.isVender,
              receiverId: receiverId,
              receiverEmail: receiverEmail,
              receiverName: receiverName,
              initMessage: initMessage,
            );
      },
    );
  }
}
