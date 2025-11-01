import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fstore/services/services.dart';

import '../../impl/firebase_service.dart';
import '../data/firestore.dart';
import '../models/entities/chat_message.dart';
import '../models/entities/chat_room.dart';
import '../models/entities/chat_user.dart';
import 'base/chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirebaseFirestore get _firestore => _firebaseServices.firestore;

  late final FirebaseServices _firebaseServices;
  late final FirestoreChat _firestoreChat;

  final ChatUser _sender;

  FirestoreChatRepository(this._sender) {
    final firebaseService = Services().firebase;
    if (firebaseService is! FirebaseServices) {
      throw Exception(
          'FirestoreChatRepository requires FirebaseServices implementation, '
          'but got ${firebaseService.runtimeType}');
    }

    _firebaseServices = firebaseService;
    _firebaseServices.getMessagingToken().then((token) {
      _pushToken = token;
    });
    _firestoreChat = FirestoreChat(_firestore);
  }

  String? _pushToken;

  @override
  ChatUser get sender => _sender;

  @override
  Stream<List<ChatRoom>> getChatRooms(bool getAllChatRooms) {
    return _firestoreChat.getChatRooms().map((snapshot) {
      return snapshot.docs
          .map<ChatRoom?>((doc) {
            final data = doc.data();

            if (getAllChatRooms) {
              return data;
            }

            // Check if user is a member of the chat room.
            if (!data.users.any((e) => e.isSameUser(user: _sender))) {
              return null;
            }
            return data;
          })
          .whereType<ChatRoom>()
          .toList();
    });
  }

  @override
  Stream<ChatRoom?> getChatRoom(String roomId) {
    return _firestoreChat.getChatRoom(roomId).map((snapshot) {
      return snapshot.data();
    });
  }

  @override
  Stream<List<ChatMessage>> getConversation(String chatId) {
    return _firestoreChat.getConversation(chatId).map((snapshot) {
      return snapshot.docs.map<ChatMessage>((doc) {
        return doc.data();
      }).toList();
    });
  }

  @override
  Future<void> sendChatMessage(
    String chatId,
    String message,
  ) async {
    await _firestoreChat.sendChatMessage(
      chatId,
      _sender,
      message,
    );
  }

  @override
  Future<void> updateTypingStatus(
    String chatId, {
    bool? isTyping,
  }) async {
    await _firestoreChat.updateTypingStatus(
      chatId,
      isTyping: isTyping,
      sender: _sender,
    );
  }

  @override
  Future<void> updateChatRoom(
    String chatId, {
    String? latestMessage,
    int? receiverUnreadCountPlus,
  }) async {
    await _firestoreChat.updateChatRoom(
      chatId,
      latestMessage: latestMessage,
      receiverUnreadCountPlus: receiverUnreadCountPlus,
      sender: _sender,
      pushToken: _pushToken,
    );
  }

  @override
  Future<void> deleteChatRoom(String chatId) async {
    await _firestoreChat.deleteChatRoom(chatId);
  }

  @override
  Future<String> getChatRoomId(ChatUser receiver) {
    return _firestoreChat.getChatRoomId(_sender, receiver);
  }

  @override
  Future<void> updateBlackList(
    String chatId, {
    List<String>? blackList,
  }) async {
    return _firestoreChat.updateBlackList(
      chatId,
      blackList: blackList,
      sender: _sender,
      pushToken: _pushToken,
    );
  }

  @override
  Future<void> exitChatRoom(String chatId) async {
    await updateTypingStatus(chatId, isTyping: false);
  }

  @override
  Future<void> exitChat() async {
    return Future.value();
  }
}
