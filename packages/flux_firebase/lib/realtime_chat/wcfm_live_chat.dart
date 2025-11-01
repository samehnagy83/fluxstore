import 'package:flutter/material.dart';

import 'realtime_chat.dart';
import 'ui/chat_auth/wcfm_live_chat_auth.dart';

class WCFMLiveChat extends StatelessWidget {
  const WCFMLiveChat({
    super.key,
    required this.chatArgs,
  });

  final ChatArgs chatArgs;

  @override
  Widget build(BuildContext context) {
    if (chatArgs.type == RealtimeChatType.userToUser) {
      return WcfmLiveChatAuth(
        chatArgs: chatArgs,
      );
    }

    return RealtimeChat(
      chatArgs: chatArgs,
    );
  }
}
