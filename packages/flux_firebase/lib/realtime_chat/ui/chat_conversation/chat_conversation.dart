import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../models/chat_view_model.dart';
import '../../models/entities/chat_room.dart';
import 'widgets/chat_appbar.dart';
import 'widgets/chat_input.dart';
import 'widgets/chat_message_list.dart';

class ChatConversation extends StatefulWidget {
  const ChatConversation({
    super.key,
    required this.isFromChatList,
    this.initMessage,
  });

  final bool isFromChatList;
  final String? initMessage;

  @override
  State<ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends State<ChatConversation> {
  ChatViewModel get model => context.read<ChatViewModel>();

  StreamSubscription? _deleteChatRoomSubscription;
  Stream<ChatRoom?>? _previousRoomStream;

  void _showEndChat(event) async {
    if (!mounted) {
      return;
    }

    if (model.isWcfmLiveChat == false) {
      return;
    }

    if (event == null) {
      if (model.userEndChatBySelf == true) {
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(S.of(context).notice),
          content: Text(S.of(context).chatEnded),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).ok),
            ),
          ],
        ),
      );

      if (!widget.isFromChatList) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    }
  }

  Future<bool> _onTapBack() async {
    final chatRoomId = model.selectedChatRoomId;
    if (chatRoomId != null) {
      await model.exitChatRoom();
      return !widget.isFromChatList;
    }
    return true;
  }

  @override
  void dispose() {
    _deleteChatRoomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScopeWidget(
      onWillPop: _onTapBack,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ChatAppbar(
            isFromChatList: widget.isFromChatList,
            onBack: _onTapBack,
          ),
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: ConsumerSelector<ChatViewModel, String?>(
            selector: (BuildContext __, ChatViewModel chatViewModel) =>
                chatViewModel.selectedChatRoomId,
            listener: (context, value) {
              final newStream =
                  context.read<ChatViewModel>().selectedChatRoomStream;

              if (newStream != _previousRoomStream) {
                _deleteChatRoomSubscription?.cancel();
                _previousRoomStream = newStream;
                _deleteChatRoomSubscription = newStream.listen(_showEndChat);
              }
            },
            builder: (BuildContext context, String? chatRoomId, __) {
              if (chatRoomId == null) {
                // Not used.
                return const SizedBox();
              }
              return AutoHideKeyboard(
                child: Column(
                  children: [
                    Expanded(child: ChatMessageList(chatRoomId: chatRoomId)),
                    const Divider(height: 1),
                    ChatInput(
                      isFromChatList: widget.isFromChatList,
                      initMessage: widget.initMessage,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ConsumerSelector<M, V> extends StatelessWidget {
  const ConsumerSelector({
    super.key,
    required this.builder,
    required this.selector,
    this.shouldRebuild,
    this.child,
    this.listener,
  });

  final ValueWidgetBuilder<V> builder;
  final void Function(BuildContext context, V value)? listener;
  final V Function(BuildContext, M) selector;
  final ShouldRebuild<V>? shouldRebuild;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Selector<M, V>(
      selector: selector,
      shouldRebuild: shouldRebuild,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          listener?.call(context, value);
        });

        return builder(context, value, child);
      },
    );
  }
}
