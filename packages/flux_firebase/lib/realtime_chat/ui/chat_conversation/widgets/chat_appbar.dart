import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:provider/provider.dart';

import '../../../models/chat_view_model.dart';
import '../../../models/entities/chat_room.dart';
import '../../../models/entities/chat_user.dart';

enum _Action {
  delete,
  block,
  endChat,
}

class ChatAppbar extends StatelessWidget {
  const ChatAppbar({
    super.key,
    required this.isFromChatList,
    required this.onBack,
  });

  final bool isFromChatList;
  final Future<bool> Function() onBack;

  Future<bool?> _confirmedDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmedButton,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmedButton),
          ),
        ],
      ),
    );
  }

  Future<void> _showLoadingDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _renderAction(
    BuildContext context,
    ChatUser? senderUser,
    ChatUser? receiverUser,
  ) {
    final isSenderBlockReceiver =
        senderUser?.blackList.contains(receiverUser?.email) ?? false;
    final isReceiverBlockSender =
        receiverUser?.blackList.contains(senderUser?.email) ?? false;

    final viewModel = context.read<ChatViewModel>();
    final chatRoomId = viewModel.selectedChatRoomId;

    final actions = <PopupMenuEntry<_Action>>[];
    if (viewModel.userCanDeleteChat &&
        !isReceiverBlockSender &&
        !isSenderBlockReceiver) {
      actions.add(
        PopupMenuItem<_Action>(
          value: _Action.delete,
          child: Text(S.of(context).deleteConversation),
        ),
      );
    }

    if (viewModel.userCanBlockAnotherUser && !isReceiverBlockSender) {
      actions.add(
        PopupMenuItem<_Action>(
          value: _Action.block,
          child: Text(
            isSenderBlockReceiver
                ? S.of(context).unblockUser
                : S.of(context).blockUser,
          ),
        ),
      );
    }

    if (viewModel.isWcfmLiveChat) {
      actions.add(
        PopupMenuItem<_Action>(
          value: _Action.endChat,
          child: Text(S.of(context).endChat),
        ),
      );
    }

    if (actions.isEmpty ||
        senderUser == null ||
        receiverUser == null ||
        chatRoomId == null) {
      return const SizedBox();
    }

    return PopupMenuButton<_Action>(
      icon: const Icon(Icons.more_vert),
      onSelected: (item) async {
        if (item == _Action.delete) {
          final confirmed = await _confirmedDialog(
            context,
            title: S.of(context).deleteConversation,
            content: S.of(context).confirmDelete,
            confirmedButton: S.of(context).delete,
          );
          if (confirmed == true) {
            /// Delete conversation.
            unawaited(_showLoadingDialog(context));
            await viewModel.deleteCurrentChatRoom();
            _hideLoadingDialog(context);
          }
          return;
        }

        if (item == _Action.endChat) {
          final confirmed = await _confirmedDialog(
            context,
            title: S.of(context).endChat,
            content: S.of(context).areYouSureEndChat,
            confirmedButton: S.of(context).confirm,
          );
          if (confirmed == true) {
            /// End conversation.
            unawaited(_showLoadingDialog(context));
            await viewModel.deleteCurrentChatRoom();
            _hideLoadingDialog(context);

            if (!isFromChatList) {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              }
            }
          }
          return;
        }

        if (item == _Action.block) {
          final blackList = List<String>.from(senderUser.blackList);
          if (isSenderBlockReceiver) {
            final confirmed = await _confirmedDialog(
              context,
              title: S.of(context).unblockUser,
              content: S.of(context).doYouWantToUnblock,
              confirmedButton: S.of(context).unblock,
            );

            if (confirmed == true) {
              /// Unblock user
              blackList.remove(receiverUser.email);
              await viewModel.updateBlackList(blackList);
            }
          } else {
            final confirmed = await _confirmedDialog(
              context,
              title: S.of(context).blockUser,
              content: S.of(context).willNotSendAndReceiveMessage,
              confirmedButton: S.of(context).block,
            );

            if (confirmed == true) {
              /// Block user
              blackList.add(receiverUser.email ?? '');
              await viewModel.updateBlackList(blackList);
            }
          }
        }
      },
      itemBuilder: (context) => actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.read<ChatViewModel>();

    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.cardColor,
      leading: BackButton(
        onPressed: () async {
          final result = await onBack.call();
          if (result) {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            }
          }
        },
      ),
      titleSpacing: 0.0,
      title: Selector<ChatViewModel, String?>(
        selector: (BuildContext __, ChatViewModel chatViewModel) =>
            chatViewModel.selectedChatRoomId,
        child: Row(
          children: [
            Text(
              S.of(context).message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        builder: (BuildContext context, String? chatRoomId, Widget? child) {
          if (chatRoomId == null) {
            return child!;
          }
          return StreamBuilder<ChatRoom?>(
            stream: model.selectedChatRoomStream,
            builder: (context, snapshot) {
              final selectedChatRoom = snapshot.data;

              if (selectedChatRoom == null) {
                return child!;
              }

              final senderUser = selectedChatRoom.getSenderUser(model.sender);
              final receiverUser =
                  selectedChatRoom.getFirstReceiverUser(model.sender);

              if (receiverUser == null) {
                return child!;
              }

              final displayName =
                  receiverUser.displayName ?? S.of(context).message;
              return Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(receiverUser.avatarImageUrl),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: receiverUser.email ?? '',
                          waitDuration: const Duration(milliseconds: 500),
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (receiverUser.isActiveNa == false)
                          Row(
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: receiverUser.isActive == true
                                      ? Colors.green
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: receiverUser.isActive == true
                                        ? Colors.green
                                        : theme.disabledColor,
                                    width: 1,
                                  ),
                                ),
                                child: const SizedBox(
                                  width: 8,
                                  height: 8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                receiverUser.displayLastActive(S.of(context)) ??
                                    '',
                                style: TextStyle(
                                  color: receiverUser.isActive == true
                                      ? Colors.green
                                      : theme.disabledColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _renderAction(context, senderUser, receiverUser),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
