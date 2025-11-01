import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_view_model.dart';
import '../../models/entities/chat_room.dart';
import '../../realtime_chat.dart';
import '../chat_conversation/chat_conversation.dart';
import 'widgets/chat_room_list.dart';

class ChatRooms extends StatelessWidget {
  const ChatRooms({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ChatViewModel, Stream<List<ChatRoom>>>(
      selector: (BuildContext __, ChatViewModel chatViewModel) =>
          chatViewModel.chatRooms,
      builder: (BuildContext _, Stream<List<ChatRoom>> stream, __) {
        return StreamBuilder<List<ChatRoom>>(
          stream: stream,
          builder:
              (BuildContext context, AsyncSnapshot<List<ChatRoom>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const Center(
                  child: CircularProgressIndicator(),
                );
              case ConnectionState.active:
                if (snapshot.hasError) {
                  if ('${snapshot.error}'.contains('permission-denied')) {
                    return const ChatAuth();
                  }

                  final surfaceColor = Theme.of(context).colorScheme.surface;
                  return Scaffold(
                    backgroundColor: surfaceColor,
                    appBar: AppBar(
                      backgroundColor: surfaceColor,
                    ),
                    body: Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else if (snapshot.hasData) {
                  final chatRooms = snapshot.data!;

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: (context.select((ChatViewModel chatViewModel) =>
                            chatViewModel.selectedChatRoomId != null))
                        ? const ChatConversation(isFromChatList: true)
                        : ChatRoomList(chatRooms: chatRooms),
                  );
                }
                return const SizedBox.shrink();
              default:
                return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}
