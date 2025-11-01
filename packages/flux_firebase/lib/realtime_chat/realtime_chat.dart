import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fstore/common/config.dart';
import 'package:fstore/common/constants.dart';
import 'package:fstore/common/events.dart';
import 'package:provider/provider.dart';

import 'constants/enums.dart';
import 'models/chat_view_model.dart';
import 'models/entities/chat_user.dart';
import 'repos/firestore_chat_repository.dart';
import 'repos/realtime_chat_repository.dart';
import 'ui/chat_conversation/chat_conversation.dart';
import 'ui/chat_rooms/chat_rooms.dart';

export 'constants/enums.dart';
export 'models/entities/chat_user.dart';
export 'ui/chat_auth/chat_auth.dart';

class ChatArgs {
  const ChatArgs({
    required this.type,
    required this.sender,
    required this.receiver,
    required this.admin,
    this.initMessage,
    this.isWcfmLiveChat = false,
  });

  final RealtimeChatType type;

  /// If the [isWcfmLiveChat] is true, [sender] can be guest
  /// Otherwise, it is required
  final ChatUser sender;

  /// If the [type] is [RealtimeChatType.userToUser], [receiver] is required
  final ChatUser? receiver;

  /// [admin] is required
  final ChatUser? admin;

  /// Initial message
  final String? initMessage;

  /// Check if the chat is from WCFM Live Chat
  final bool isWcfmLiveChat;

  ChatArgs copyWith({
    RealtimeChatType? type,
    ChatUser? sender,
    ChatUser? receiver,
    ChatUser? admin,
    String? initMessage,
    bool? isWcfmLiveChat,
  }) {
    return ChatArgs(
      type: type ?? this.type,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      admin: admin ?? this.admin,
      initMessage: initMessage ?? this.initMessage,
      isWcfmLiveChat: isWcfmLiveChat ?? this.isWcfmLiveChat,
    );
  }
}

class RealtimeChat extends StatefulWidget {
  const RealtimeChat({
    super.key,
    required this.chatArgs,
  });

  final ChatArgs chatArgs;

  @override
  State<RealtimeChat> createState() => _RealtimeChatState();
}

class _RealtimeChatState extends State<RealtimeChat> {
  ChatArgs get chatArgs => widget.chatArgs;

  late final ChatViewModel _viewModel;

  StreamSubscription? _subscription;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      _init();
      _subscription = eventBus.on<EventExpiredCookie>().listen((event) {
        _isInitialized = false;
        if (mounted) {
          setState(() {});
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (_isInitialized) {
      return;
    }

    var repo;
    if (chatArgs.isWcfmLiveChat) {
      final isAdmin = chatArgs.sender.isSameUser(user: chatArgs.admin);
      repo = RealtimeChatRepository(chatArgs.sender, isAdmin);
      await (repo as RealtimeChatRepository).initSenderUser();
    } else {
      repo = FirestoreChatRepository(chatArgs.sender);
    }

    _viewModel = ChatViewModel(
      chatArgs.type,
      chatArgs.isWcfmLiveChat,
      chatArgs.receiver,
      chatArgs.admin,
      repo,
    );

    _isInitialized = true;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(
        child: kLoadingWidget(context),
      );
    }

    final media = MediaQuery.of(context);

    return LayoutBuilder(builder: (_, constraints) {
      final heightBottomBar = (constraints.maxHeight != double.infinity)
          ? MediaQuery.sizeOf(context).height - constraints.maxHeight
          : (ScreenUtil.bottomBarHeight ?? 0.0);

      return MediaQuery(
        data: media.copyWith(
          viewInsets: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom - heightBottomBar,
          ),
        ),
        child: Scaffold(
          body: ChangeNotifierProvider<ChatViewModel>(
            create: (BuildContext context) => _viewModel,
            builder: (BuildContext context, Widget? child) {
              switch (chatArgs.type) {
                case RealtimeChatType.userToUsers:
                  return const ChatRooms();
                case RealtimeChatType.userToUser:
                  return ChatConversation(
                    isFromChatList: false,
                    initMessage: chatArgs.initMessage,
                  );
              }
            },
          ),
        ),
      );
    });
  }
}
