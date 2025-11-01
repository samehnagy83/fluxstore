import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fstore/common/config.dart';
import 'package:fstore/common/config/models/config_chat.dart';

import '../constants/enums.dart';
import '../repos/base/chat_repository.dart';
import 'entities/chat_message.dart';
import 'entities/chat_room.dart';
import 'entities/chat_user.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  final bool _isWcfmLiveChat;
  final ChatUser? _admin;
  ChatUser? _receiver;

  ChatViewModel(
    RealtimeChatType type,
    this._isWcfmLiveChat,
    this._receiver,
    this._admin,
    this._repository,
  ) {
    _init(type);
  }

  bool get isAdmin => _repository.sender.isSameUser(user: _admin);

  ChatUser get sender => _repository.sender;
  ChatUser? get admin => _admin;

  bool get isWcfmLiveChat => _isWcfmLiveChat;

  Stream<List<ChatRoom>> _chatRooms = const Stream.empty();

  Stream<List<ChatRoom>> get chatRooms => _chatRooms;

  String? _selectedChatRoomId;

  String? get selectedChatRoomId => _selectedChatRoomId;

  set selectedChatRoomId(String? value) {
    _selectedChatRoomId = value;
    notifyListeners();
  }

  Stream<ChatRoom?> get selectedChatRoomStream => _selectedChatRoomId != null
      ? _repository.getChatRoom(_selectedChatRoomId!)
      : const Stream.empty();

  Stream<List<ChatMessage>> get chatConversation => _selectedChatRoomId != null
      ? _repository.getConversation(_selectedChatRoomId!)
      : const Stream.empty();

  /// Only used for WCFM Live Chat.
  /// true: user ended the chat
  /// false: someone else ended the chat
  /// null: chat not ended
  bool? userEndChatBySelf;

  Future<void> _init(RealtimeChatType type) async {
    if (type == RealtimeChatType.userToUsers) {
      final isAllowAdminGetAllChatRooms = isAdmin && adminCanAccessAllChatRooms;
      _chatRooms = _repository.getChatRooms(isAllowAdminGetAllChatRooms);
    } else if (type == RealtimeChatType.userToUser) {
      // If the [type] is [RealtimeChatType.userToUser], [receiver] is required.
      // If [receiver] is null, chat with admin instead
      _receiver ??= admin;
    }

    // Open the chat screen if the receiver is specific
    if (_receiver != null) {
      _selectedChatRoomId = await _repository.getChatRoomId(_receiver!);
    }
    notifyListeners();
  }

  RealtimeChatConfig get realtimeChatConfig => kConfigChat.realtimeChatConfig;

  bool get userCanDeleteChat =>
      realtimeChatConfig.userCanDeleteChat && !_isWcfmLiveChat;

  bool get userCanBlockAnotherUser =>
      realtimeChatConfig.userCanBlockAnotherUser && !_isWcfmLiveChat;

  bool get adminCanAccessAllChatRooms =>
      realtimeChatConfig.adminCanAccessAllChatRooms && !_isWcfmLiveChat;

  Future<void> sendChatMessage(String message) async {
    if (_selectedChatRoomId == null) {
      return;
    }

    await _repository.sendChatMessage(
      _selectedChatRoomId!,
      message,
    );
    await _repository.updateChatRoom(
      _selectedChatRoomId!,
      latestMessage: message,
      receiverUnreadCountPlus: 1,
    );
  }

  Future<void> updateTypingStatus(bool status) async {
    if (_selectedChatRoomId == null) {
      return;
    }

    await _repository.updateTypingStatus(
      _selectedChatRoomId!,
      isTyping: status,
    );
  }

  Future<void> deleteCurrentChatRoom() async {
    if (_selectedChatRoomId == null) {
      return;
    }

    userEndChatBySelf = true;
    await _repository.deleteChatRoom(_selectedChatRoomId!);
    _selectedChatRoomId = null;
    notifyListeners();
  }

  Future<void> updateBlackList(List<String> emails) async {
    if (_selectedChatRoomId == null) {
      return;
    }

    return _repository.updateBlackList(
      _selectedChatRoomId!,
      blackList: emails,
    );
  }

  Future<void> exitChatRoom() async {
    if (_selectedChatRoomId == null) {
      return;
    }

    await _repository.exitChatRoom(_selectedChatRoomId!);
    _selectedChatRoomId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.exitChat();
    super.dispose();
  }
}
