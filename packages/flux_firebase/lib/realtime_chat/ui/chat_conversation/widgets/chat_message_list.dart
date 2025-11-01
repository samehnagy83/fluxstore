import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_message.dart';
import '../../../models/entities/chat_user.dart';
import '../../chat_auth/chat_auth.dart';
import 'chat_message_bubble.dart';
import 'chat_typing_status.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key, required this.chatRoomId});

  final String chatRoomId;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  int _lastReceiverMessageIndex = 0;
  int _lastSenderMessageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Selector<ChatViewModel, Stream<List<ChatMessage>>>(
      selector: (BuildContext __, ChatViewModel chatViewModel) =>
          chatViewModel.chatConversation,
      builder: (BuildContext _, Stream<List<ChatMessage>> stream, __) {
        return StreamBuilder<List<ChatMessage>>(
          stream: stream,
          builder: (BuildContext context,
              AsyncSnapshot<List<ChatMessage>> snapshot) {
            if (snapshot.hasError) {
              if ('${snapshot.error}'.contains('permission-denied')) {
                return const ChatAuth();
              }
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }
            if (snapshot.hasData == false) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              final chatMessages = snapshot.data!;
              final model = context.read<ChatViewModel>();
              _lastReceiverMessageIndex = chatMessages.indexWhere(
                (ChatMessage message) => !model.sender.isSameUser(
                  email: message.sender,
                  id: message.sender,
                ),
              );
              _lastSenderMessageIndex = chatMessages.indexWhere(
                (ChatMessage message) => model.sender.isSameUser(
                  email: message.sender,
                  id: message.sender,
                ),
              );
              return ListView.builder(
                key: ValueKey(widget.chatRoomId),
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                itemCount: chatMessages.length + 1,
                itemBuilder: (context, fakeIndex) {
                  if (fakeIndex == 0) {
                    return const ChatTypingStatus();
                  }
                  final index = fakeIndex - 1;
                  final msg = chatMessages[index];
                  final shouldShowInfo = (index + 1) == chatMessages.length ||
                      chatMessages[index + 1].sender != msg.sender;
                  final isLastMessage = index == _lastSenderMessageIndex ||
                      index == _lastReceiverMessageIndex;
                  var diffWithNextInMin = (index + 1) != chatMessages.length
                      ? (chatMessages[index + 1]
                              .createdAt
                              .difference(msg.createdAt)
                              .inMinutes)
                          .abs()
                      : 0;

                  var diffWithPrevInMin = index != 0
                      ? (chatMessages[index - 1]
                              .createdAt
                              .difference(msg.createdAt)
                              .inMinutes)
                          .abs()
                      : 0;

                  if (diffWithNextInMin < Duration.minutesPerHour / 4) {
                    diffWithNextInMin = 0;
                  }
                  if (diffWithPrevInMin < Duration.minutesPerHour / 4) {
                    diffWithPrevInMin = 0;
                  }

                  final isNextMessageFromSameSender =
                      (index + 1) != chatMessages.length &&
                          chatMessages[index + 1].sender == msg.sender;

                  final isPrevMessageFromSameSender = index != 0 &&
                      chatMessages[index - 1].sender == msg.sender;

                  return ChatMessageBubble(
                    key: ValueKey(
                      '${widget.chatRoomId}-${msg.hashCode}',
                    ),
                    shouldShowInfo: shouldShowInfo,
                    isFirstMessage: index + 1 == chatMessages.length,
                    isLastMessage: isLastMessage,
                    chatMessage: msg,
                    diffWithNextInMin: diffWithNextInMin,
                    diffWithPrevInMin: diffWithPrevInMin,
                    isPrevMessageFromSameSender: isPrevMessageFromSameSender,
                    isNextMessageFromSameSender: isNextMessageFromSameSender,
                  );
                },
              );
            }
          },
        );
      },
    );
  }
}
