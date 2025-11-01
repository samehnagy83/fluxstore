import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fstore/data/boxes.dart';

import '../constants/keys.dart';
import '../models/entities/chat_message.dart';
import '../models/entities/chat_room.dart';
import '../models/entities/chat_user.dart';

class FirestoreChat {
  final FirebaseFirestore _firebaseFirestore;

  FirestoreChat(this._firebaseFirestore);

  Stream<QuerySnapshot<ChatRoom>> getChatRooms() {
    return _firebaseFirestore
        .collection(kFirestoreCollectionChatRooms)
        .withConverter<ChatRoom>(
          fromFirestore: (snapshot, _) => ChatRoom.fromFirestoreJson(
            snapshot.id,
            snapshot.data() ?? {},
          ),
          toFirestore: (item, _) => item.toFirestoreJson(),
        )
        .orderBy(kFirestoreOldFieldUpdatedAtForChatRooms, descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<ChatRoom>> getChatRoom(
    String roomId,
  ) {
    return _firebaseFirestore
        .collection(kFirestoreCollectionChatRooms)
        .doc(roomId)
        .withConverter<ChatRoom>(
          fromFirestore: (snapshot, _) {
            return ChatRoom.fromFirestoreJson(
              snapshot.id,
              snapshot.data() ?? {},
            );
          },
          toFirestore: (item, _) => item.toFirestoreJson(),
        )
        .snapshots();
  }

  Stream<QuerySnapshot<ChatMessage>> getConversation(String chatId) {
    return _firebaseFirestore
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .collection(kFirestoreCollectionChatScreen)
        .orderBy(
          kFirestoreFieldCreatedAt,
          descending: true,
        )
        .withConverter<ChatMessage>(
          fromFirestore: (snapshot, _) => ChatMessage.fromFirestoreJson(
            snapshot.data() ?? {},
          ),
          toFirestore: (chatMessage, _) => chatMessage.toFirestoreJson(),
        )
        .snapshots();
  }

  Future<DocumentReference<ChatMessage>> sendChatMessage(
    String chatId,
    ChatUser sender,
    String message,
  ) async {
    return _firebaseFirestore
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .collection(kFirestoreCollectionChatScreen)
        .withConverter<ChatMessage>(
          fromFirestore: (snapshot, _) => ChatMessage.fromFirestoreJson(
            snapshot.data() ?? {},
          ),
          toFirestore: (chatMessage, _) => chatMessage.toFirestoreJson(),
        )
        .add(
          ChatMessage(
            createdAt: DateTime.now(),
            sender: sender.email ?? '',
            senderName: sender.name,
            avatarImage: sender.avatarImage,
            text: message,
          ),
        );
  }

  Future<void> updateTypingStatus(
    String chatId, {
    bool? isTyping = false,
    ChatUser? sender,
    String? pushToken,
  }) async {
    return updateChatRoom(
      chatId,
      isTyping: isTyping,
      sender: sender,
      pushToken: pushToken,
    );
  }

  Future<ChatRoom> initChatRoom(
    String chatId, {
    ChatUser? sender,
    ChatUser? receiver,
  }) async {
    final ref = getChatRoomReference(
      chatId,
    );
    final snapshot = await ref.get();
    final data = snapshot.data();
    final chatRoom = data ??
        ChatRoom(
          chatId,
          updatedAt: data?.updatedAt ?? DateTime.now(),
        );
    final users = List<ChatUser>.from(chatRoom.users);
    var shouldUpdateUsers = users.isEmpty;

    if (sender != null && users.every((e) => !e.isSameUser(user: sender))) {
      users.add(sender);

      shouldUpdateUsers = true;
    }

    if (receiver != null && users.every((e) => !e.isSameUser(user: receiver))) {
      users.add(receiver);

      shouldUpdateUsers = true;
    }

    if (!snapshot.exists || shouldUpdateUsers) {
      final newChatRoom = chatRoom.copyWith(users: users);
      await ref.set(newChatRoom);
      return newChatRoom;
    }

    return chatRoom;
  }

  Future updateChatRoom(
    String chatId, {
    String? latestMessage,
    int? receiverUnreadCountPlus,
    bool? isTyping,
    List<String>? blackList,
    ChatUser? sender,
    ChatUser? receiver,
    String? pushToken,
  }) async {
    final newLangCode = SettingsBox().languageCode;
    var chatRoom = await initChatRoom(chatId, sender: sender);

    final currentUsers = chatRoom.users.map((e) {
      if (e.isSameUser(user: sender)) {
        return e.copyWith(
          lastActive: DateTime.now(),
          unread: 0,
          languageCode: newLangCode,
          isTyping: isTyping,
          blackList: blackList,
          pushToken: pushToken != null &&
                  pushToken.isNotEmpty &&
                  e.pushToken != pushToken
              ? pushToken
              : null,
        );
      } else {
        return e.copyWith(
          unread: e.unread + (receiverUnreadCountPlus ?? 0),
        );
      }
    }).toList();

    chatRoom = chatRoom.copyWith(
        latestMessage: latestMessage,
        updatedAt: latestMessage != null ? DateTime.now() : null,
        users: currentUsers);
    return _firebaseFirestore
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .update(chatRoom.toFirestoreJson());
  }

  Future<void> deleteChatRoom(String chatId) async {
    /// Get all messages in the chat room.
    final allMessages = await _firebaseFirestore
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .collection(kFirestoreCollectionChatScreen)
        .get();

    /// Delete all the chat room's messages.
    final futures = <Future>[];
    for (DocumentSnapshot document in allMessages.docs) {
      futures.add(document.reference.delete());
    }
    await Future.wait(futures);

    /// Delete the chat room.
    return _firebaseFirestore
        .collection(kFirestoreCollectionChatRooms)
        .doc(chatId)
        .delete();
  }

  Future<String> getChatRoomId(
    ChatUser sender,
    ChatUser receiver,
  ) async {
    var chatId = '${receiver.email}-${sender.email}';
    final snapshot = await getChatRoomReference(
      chatId,
    ).get();

    if (!snapshot.exists) {
      chatId = '${sender.email}-${receiver.email}';
    }

    await initChatRoom(
      chatId,
      sender: sender,
      receiver: receiver,
    );
    return chatId;
  }

  DocumentReference<ChatRoom> getChatRoomReference(
    String roomId,
  ) {
    return _firebaseFirestore
        .collection(kFirestoreCollectionChatRooms)
        .doc(roomId)
        .withConverter<ChatRoom>(
          fromFirestore: (snapshot, _) {
            if (!snapshot.exists) {}
            return ChatRoom.fromFirestoreJson(
              snapshot.id,
              snapshot.data() ?? {},
            );
          },
          toFirestore: (item, _) => item.toFirestoreJson(),
        );
  }

  Future<void> updateBlackList(
    String chatId, {
    List<String>? blackList,
    ChatUser? sender,
    String? pushToken,
  }) async {
    return updateChatRoom(
      chatId,
      sender: sender,
      pushToken: pushToken,
      blackList: blackList,
    );
  }
}
