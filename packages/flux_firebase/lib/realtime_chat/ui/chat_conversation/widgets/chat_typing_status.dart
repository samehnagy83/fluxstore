import 'package:flutter/material.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_room.dart';
import '../../../models/entities/chat_user.dart';

class ChatTypingStatus extends StatelessWidget {
  const ChatTypingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.read<ChatViewModel>();
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Selector<ChatViewModel, String?>(
        selector: (BuildContext __, ChatViewModel chatViewModel) =>
            chatViewModel.selectedChatRoomId,
        child: const SizedBox(width: double.infinity),
        builder: (BuildContext context, String? chatRoomId, Widget? child) {
          if (chatRoomId == null) {
            return child!;
          }
          return StreamBuilder<ChatRoom?>(
            stream: model.selectedChatRoomStream,
            builder: (context, snapshot) {
              final chatRoom = snapshot.data;

              // Take max 3 users
              final usersTyping = chatRoom
                      ?.getOtherUsers(model.sender)
                      .where((user) => user.isTyping)
                      .take(3) ??
                  [];

              if (usersTyping.isEmpty) {
                return child!;
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        for (var i = 0; i < usersTyping.length; i++)
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: 8.0 * i),
                            child: CircleAvatar(
                              radius: 10,
                              child: CircleAvatar(
                                radius: 8.0,
                                backgroundImage: NetworkImage(
                                  usersTyping.elementAt(i).avatarImageUrl,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8.0),
                    JumpingDots(
                      animationDuration: const Duration(milliseconds: 200),
                      innerPadding: 3,
                      radius: 4,
                      verticalOffset: 8,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
