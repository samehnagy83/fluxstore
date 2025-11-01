import 'package:fstore/common/tools/gravatar.dart';
import 'package:fstore/services/service_config.dart';
import 'package:fstore/services/services.dart';
import 'package:http/http.dart' as http;

import '../../impl/firebase_service.dart';
import '../data/database.dart';
import '../models/entities/chat_message.dart';
import '../models/entities/chat_room.dart';
import '../models/entities/chat_user.dart';
import 'base/chat_repository.dart';

const _userPrefix = 'usr-';
const _operatorPrefix = 'fbc-op-';

class RealtimeChatRepository implements ChatRepository {
  late final DatabaseChat _realtimeChat;

  late final ChatUser _sender;

  /// The guest ID, stored in memory, will be reset when the user reopens the
  /// app or after logging in
  static String? _guestId;
  static String? _guestEmail;

  String? _pushToken;
  late final bool _isOperator;
  String? _senderConversationId;

  RealtimeChatRepository(final ChatUser sender, this._isOperator) {
    final firebaseService = Services().firebase;
    if (firebaseService is! FirebaseServices) {
      throw Exception(
          'RealtimeChatRepository requires FirebaseServices implementation, '
          'but got ${firebaseService.runtimeType}');
    }

    firebaseService.getMessagingToken().then((token) {
      _pushToken = token;
    });
    _realtimeChat = DatabaseChat(firebaseService.database);

    final isGuest = sender.id?.isEmpty ?? true;
    final isNewGuest = isGuest && sender.email != _guestEmail;
    if (isGuest) {
      _guestId = isNewGuest ? _realtimeChat.createNewUserId() : _guestId;
      _guestEmail = isNewGuest ? sender.email : _guestEmail;
    } else {
      _guestId = null;
      _guestEmail = null;
    }
    final senderId = isGuest ? _guestId : '$_senderPrefix${sender.id}';

    _sender = sender.copyWith(id: senderId);
  }

  String get _senderId => _sender.id ?? '';
  String get _senderEmail => _sender.email ?? '';
  String get _senderName => _sender.name ?? '';
  bool get _isGuest => _senderId.startsWith(_senderPrefix) == false;
  String get _senderPrefix => _isOperator ? _operatorPrefix : _userPrefix;
  String get _senderType => _isOperator ? 'operator' : 'visitor';
  String get _vendorId => _sender.vendorId ?? '0';
  String get _vendorName => _sender.vendorName ?? '';

  @override
  ChatUser get sender => _sender;

  Future<String> _updateOrCreateUser(String? conversationId) async {
    var id = conversationId;

    if (id != null && id.isNotEmpty) {
      // Update sender user in Firebase
      await _realtimeChat.updateOrCreateUser(
        _senderId,
        _getUserData(
          conversationId: id,
          isOnline: true,
          pushToken: _pushToken,
        ),
      );

      return id;
    }

    // Create new conversation
    id = _realtimeChat.createNewConversationId();

    await _realtimeChat.createConversation(
      id,
      {
        'user_id': _senderId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'accepted_at': '',
        'evaluation': '',
        'user_type': _senderType,
        'receive_copy': false
      },
    );

    // Create sender user in Firebase
    await _realtimeChat.updateOrCreateUser(
      _senderId,
      _getUserData(
        conversationId: id,
        isOnline: true,
        pushToken: _pushToken,
      ),
    );

    return id;
  }

  Future<void> initSenderUser() async {
    return _realtimeChat.getConversationId(_senderId).then((event) async {
      final value = event.snapshot.value;

      if (value is Map) {
        _senderConversationId = value.keys.last?.toString();
      }

      _senderConversationId = await _updateOrCreateUser(_senderConversationId);
    });
  }

  @override
  Future<void> deleteChatRoom(String chatId) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final snapshotCnv = await _realtimeChat.getConversation(chatId).first;
    final cnv = snapshotCnv.snapshot.value as Map?;

    if (cnv == null || cnv.isEmpty) return;

    final userId = cnv['user_id'];
    final acceptedAt = cnv['accepted_at'];

    final duration = _calculateDuration(acceptedAt, now);

    final userSnapshot = await _realtimeChat.getUser(userId);
    final userData = (userSnapshot.snapshot.value as Map?) ?? {};

    userData['created_at'] = cnv['created_at'];
    userData['evaluation'] = cnv['evaluation'];
    userData['duration'] = duration;
    userData['receive_copy'] = true;
    userData['send_email'] = true;

    final allMsgsSnapshot = await _realtimeChat.getChatMessages(chatId).first;
    final allMsgs = (allMsgsSnapshot.snapshot.value as Map?) ?? {};

    final msgsData = <String, dynamic>{};

    final futures = <Future>[];
    for (final entry in allMsgs.entries) {
      final msg = entry.value as Map?;
      if (msg == null) continue;

      if (msg['conversation_id'] == chatId) {
        msgsData[entry.key] = msg;
        futures.add(_realtimeChat.deleteMessage(entry.key));
      }
    }

    try {
      userData['msgs'] = msgsData;

      await _postToServer(userData);
    } catch (e) {
      // Unable to save conversation :(
    }

    const deleteFromApp = true;
    if (deleteFromApp) {
      futures.add(_realtimeChat.deleteUser(userId));
      futures.add(_realtimeChat.deleteConversation(chatId));
      await Future.wait(futures);
    }
  }

  Map<String, String> _flattenMap(Map map, [String prefix = '']) {
    final result = <String, String>{};

    map.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '$prefix[$key]';
      if (value is Map) {
        result.addAll(_flattenMap(value, newKey));
      } else {
        result[newKey] = value.toString();
      }
    });

    return result;
  }

  Future<void> _postToServer(Map data) async {
    final url = Uri.parse(
      '${ServerConfig().url}/wp-admin/admin-ajax.php?action=fbc_ajax_callback&mode=save_chat',
    );

    final header = {
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    };
    final formData = _flattenMap(data);

    final response = await http.post(
      url,
      headers: header,
      body: formData,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to post chat data to server: ${response.body}');
    }
  }

  String _calculateDuration(dynamic start, int end) {
    if (start == null || '$start'.isEmpty || end == 0) return '00:00:00';
    final startMs = start is int ? start : int.tryParse(start.toString()) ?? 0;
    final diff = ((end - startMs) ~/ 1000);

    final hours = (diff ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((diff % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (diff % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  Stream<ChatRoom?> getChatRoom(String roomId) {
    return _realtimeChat.getConversation(roomId).asyncMap((event) async {
      final data = event.snapshot.value as Map?;

      if (data == null) {
        return null;
      }

      // Add sender user to this room
      final users = [_sender.copyWith(lastActive: DateTime.now())];

      // This userId could be receiver id or sender id
      final userId = data['user_id'];
      final typingUsers = data['typing'] is Map ? data['typing'] as Map : {};
      var lastActive = DateTime.now();

      // If Vendor/Admin chat to Guest/User
      if (_isOperator && userId != null && userId != _senderId) {
        // Get Guest/User information
        final user = await _getUser(userId);
        if (user != null) {
          lastActive = user.lastActive ?? DateTime.now();
          users.add(
            user.copyWith(
              isTyping: typingUsers[userId] != null,
            ),
          );
        }
      }

      // Add other users to this room
      for (var userMap in typingUsers.entries) {
        final userId = userMap.key;
        final userName = userMap.value;
        if (userId != _senderId) {
          // Update existing user
          if (users.any((e) => e.id == userId)) {
            // Do nothing :))
          } else {
            // User is typing means user is online
            users.add(ChatUser(
              id: userId,
              name: userName,
              isTyping: true,
              lastActive: DateTime.now(),
              isOnline: true,
            ));
          }
        }
      }

      // If Guest/User to Vendor/Admin
      if (_isOperator == false) {
        if (users.every((e) => e.id != _vendorId)) {
          if (_vendorId != '0') {
            final vendor = await _getUser('$_operatorPrefix$_vendorId');
            if (vendor != null) {
              users.add(
                vendor.copyWith(
                  isTyping: typingUsers[_vendorId] != null,
                ),
              );
            } else {
              // Add fake vendor user to show vendor name on chat appbar if there is
              // no vendor user
              users.add(ChatUser(
                id: _vendorId,
                name: _vendorName,
              ));
            }
          } else {
            // Add fake admin user to show admin name on chat appbar if there is
            // no admin user
            users.add(ChatUser(
              id: _vendorId,
              name: _vendorName,
            ));
          }
        }
      }

      return ChatRoom(
        roomId,
        updatedAt: lastActive,
        users: users,
      );
    });
  }

  @override
  Future<String> getChatRoomId(ChatUser receiver) {
    // Get user conversation id, not vendor/admin conversation id
    final userId = _isOperator ? receiver.id ?? '' : _senderId;
    return _realtimeChat.getConversationId(userId).then((event) async {
      String? conversationId;
      final value = event.snapshot.value;

      if (value is Map) {
        conversationId = value.keys.last?.toString();
      }

      // Create new conversation
      conversationId = await _updateOrCreateUser(conversationId);

      return conversationId;
    });
  }

  @override
  Stream<List<ChatRoom>> getChatRooms(bool getAllChatRooms) {
    return _realtimeChat.getChatRooms().map((event) {
      return event.snapshot.children
          .map<ChatRoom?>((doc) {
            final data = doc.value as Map?;
            // Ignore invalid user
            if (data == null ||
                data.isEmpty ||
                data['user_id'] == null ||
                data['conversation_id'] == null ||
                data['user_id'] == _senderId) {
              return null;
            }

            if (getAllChatRooms == false) {
              if (data['user_type'] != 'visitor' ||
                  data['vendor_id']?.toString() != _vendorId) {
                return null;
              }
            }

            final user = ChatUser.fromRealtimeJson(data);

            return ChatRoom(
              data['conversation_id'],
              updatedAt: user.lastActive ?? DateTime.now(),
              users: [sender, user],
            );
          })
          .whereType<ChatRoom>()
          .toList()
          .reversed
          .toList();
    });
  }

  @override
  Stream<List<ChatMessage>> getConversation(String chatId) {
    return _realtimeChat.getChatMessages(chatId).map((event) {
      final messages = <ChatMessage>[];
      for (final rawMessage in event.snapshot.children) {
        final data = (rawMessage.value as Map?) ?? {};
        final chatMessage = ChatMessage.fromRealtimeJson(data);

        // TODO: Vendor can only see their messages and user messages
        // Admin/Guest/User can see all messages in the same conversation
        if (data.isNotEmpty && data['vendor_id']?.toString() == _vendorId) {
          messages.add(chatMessage);
        }
      }
      return messages.reversed.toList();
    });
  }

  @override
  Future<void> sendChatMessage(
    String chatId,
    String message,
  ) {
    final chatMessage = {
      'avatar_image': getGravatarUrl(_senderEmail),
      'avatar_type': 'image',
      'conversation_id': chatId,
      'gravatar': getGravatarHash(_senderEmail),
      'msg': message,
      'msg_time': DateTime.now().millisecondsSinceEpoch,
      'type': 'text',
      'read': false,
      'user_id': _senderId,
      'user_name': _senderName,
      'user_type': _senderType,
      'vendor_id': _vendorId,
    };

    return _realtimeChat.createChatMessage(chatMessage);
  }

  @override
  Future<void> updateBlackList(
    String chatId, {
    List<String>? blackList,
  }) {
    return Future.value();
  }

  @override
  Future<void> updateChatRoom(
    String chatId, {
    String? latestMessage,
    int? receiverUnreadCountPlus,
  }) {
    return Future.value();
  }

  @override
  Future<void> updateTypingStatus(
    String chatId, {
    bool? isTyping,
  }) {
    return _realtimeChat.updateTypingStatus(
      chatId,
      isTyping ?? false,
      _senderId,
      _senderName,
    );
  }

  @override
  Future<void> exitChatRoom(String chatId) async {
    await updateTypingStatus(chatId, isTyping: false);

    // Notify if guest user left the chat
    if (_isGuest) {
      await sendChatMessage(
        chatId,
        'The user has left the chat.',
      );
    }
  }

  @override
  Future<void> exitChat() async {
    // Remove push token for guest user
    final pushToken = _isGuest ? '' : _pushToken;

    final user = await _getUser(_senderId);

    if (user != null) {
      await _realtimeChat.updateOrCreateUser(
        _senderId,
        _getUserData(
          conversationId: _senderConversationId ?? '',
          isOnline: false,
          pushToken: pushToken,
        ),
      );
    }
  }

  Future<ChatUser?> _getUser(String userId) async {
    final userSnapshot = await _realtimeChat.getUser(userId);

    final user = userSnapshot.snapshot.value as Map?;

    if (user == null || user.isEmpty) {
      return null;
    }

    return ChatUser.fromRealtimeJson(user);
  }

  Map _getUserData({
    required String conversationId,
    required bool isOnline,
    required String? pushToken,
  }) {
    return {
      'avatar_image': getGravatarUrl(_senderEmail),
      'avatar_type': 'image',
      'chat_with': 'free',
      'conversation_id': conversationId,
      'current_page': 'Mobile App',
      'gravatar': getGravatarHash(_senderEmail),
      'is_mobile': true,
      'last_online': DateTime.now().millisecondsSinceEpoch,
      'status': isOnline ? 'online' : 'offline', // Connection status
      'user_email': _senderEmail,
      'user_id': _senderId,
      'user_ip': '127.0.0.1',
      'user_name': _senderName,
      'user_type': _senderType,
      'vendor_id': _vendorId,
      'vendor_name': _vendorName,
      'push_token': pushToken,
    };
  }
}
