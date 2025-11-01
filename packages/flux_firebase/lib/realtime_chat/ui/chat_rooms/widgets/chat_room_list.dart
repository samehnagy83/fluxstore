import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_room.dart';
import '../../../realtime_chat.dart';
import 'chat_room_item.dart';

class ChatRoomList extends StatelessWidget {
  const ChatRoomList({super.key, required this.chatRooms});

  final List<ChatRoom> chatRooms;

  /// Only for Firestore Chat.
  Widget? _rendeChatWithAdminButton(BuildContext context) {
    final chatViewModel = context.read<ChatViewModel>();

    if (chatViewModel.isAdmin || chatViewModel.isWcfmLiveChat) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealtimeChat(
              chatArgs: ChatArgs(
                type: RealtimeChatType.userToUser,
                sender: chatViewModel.sender,
                receiver: chatViewModel.admin,
                admin: chatViewModel.admin,
              ),
            ),
          ),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      tooltip: S.of(context).needHelp,
      child: Icon(
        CupertinoIcons.conversation_bubble,
        color: Theme.of(context).primaryColor,
        size: 32,
      ),
    );
  }

  void _handleChatRoomTap(BuildContext context, ChatRoom chatRoom) {
    final model = context.read<ChatViewModel>();
    if (chatRoom.id == model.selectedChatRoomId) {
      return;
    }
    model.selectedChatRoomId = chatRoom.id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        titleSpacing: 0.0,
        title: Text(
          S.of(context).conversations,
          style: textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      floatingActionButton: _rendeChatWithAdminButton(context),
      body: chatRooms.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S.of(context).noConversation,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      S.of(context).noConversationDescription,
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                return ChatRoomItem(
                  chatRoom: chatRoom,
                  onTap: () => _handleChatRoomTap(
                    context,
                    chatRoom,
                  ),
                );
              },
              itemCount: chatRooms.length,
            ),
    );
  }
}
