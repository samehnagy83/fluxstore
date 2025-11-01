import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_room.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.isFromChatList,
    this.initMessage,
  });

  final bool isFromChatList;
  final String? initMessage;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with WidgetsBindingObserver {
  ChatViewModel get model => context.read<ChatViewModel>();
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool get isTyping =>
      _textEditingController.text.isNotEmpty && _focusNode.hasFocus;

  void _sendMessage() {
    final text = _textEditingController.text.trim();
    if (text.isNotEmpty) {
      final model = context.read<ChatViewModel>();
      model.sendChatMessage(text);
      _textEditingController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initMessage?.isNotEmpty ?? false) {
      _textEditingController.text = widget.initMessage ?? '';
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        // _focusNode.requestFocus();
        _focusNode.addListener(_updateTypingStatus);
      }
    });
  }

  void _updateTypingStatus() {
    if (!mounted) {
      return;
    }
    final model = context.read<ChatViewModel>();

    EasyDebounce.debounce(
      'chat-message-update-typing-status',
      const Duration(milliseconds: 1000),
      () => model.updateTypingStatus(isTyping),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_updateTypingStatus);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && isTyping) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ChatViewModel, String?>(
      selector: (BuildContext __, ChatViewModel chatViewModel) =>
          chatViewModel.selectedChatRoomId,
      builder: (BuildContext context, String? chatRoomId, __) {
        if (chatRoomId == null) {
          // Not used.
          return const SizedBox();
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
          ),
          child: SafeArea(
            child: StreamBuilder<ChatRoom?>(
              stream: model.selectedChatRoomStream,
              builder: (context, snapshot) {
                final selectedChatRoom = snapshot.data;
                if (selectedChatRoom == null) {
                  return const SizedBox.shrink();
                }

                final senderUser = selectedChatRoom.getSenderUser(model.sender);
                final receiverUser =
                    selectedChatRoom.getFirstReceiverUser(model.sender);

                final isSenderBlockReceiver =
                    senderUser?.blackList.contains(receiverUser?.email) ??
                        false;
                final isReceiverBlockSender =
                    receiverUser?.blackList.contains(senderUser?.email) ??
                        false;

                if (isSenderBlockReceiver || isReceiverBlockSender) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.block,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isSenderBlockReceiver
                              ? S.of(context).userHasBeenBlocked
                              : S.of(context).cannotSendMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: S.of(context).typeAMessage,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(10),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            color: Theme.of(context).primaryColor,
                            onPressed: _sendMessage,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        controller: _textEditingController,
                        onChanged: (_) => _updateTypingStatus(),
                        onSubmitted: (_) => _sendMessage(),
                        onEditingComplete: _sendMessage,
                        onTapOutside: (_) => _focusNode.unfocus(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
