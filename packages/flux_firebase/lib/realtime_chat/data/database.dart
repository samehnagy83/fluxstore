import 'package:firebase_database/firebase_database.dart';

class DatabaseChat {
  final FirebaseDatabase _firebaseDatabase;

  DatabaseChat(this._firebaseDatabase);

  DatabaseReference _getChatSessionsRef() {
    return _firebaseDatabase.ref('chat_sessions');
  }

  DatabaseReference _getChatUsersRef() {
    return _firebaseDatabase.ref('chat_users');
  }

  DatabaseReference _getChatMessagesRef() {
    return _firebaseDatabase.ref('chat_messages');
  }

  /// Create a new conversation id.
  String createNewConversationId() {
    return _getChatSessionsRef().push().key ?? '';
  }

  /// Get a chat session from user id.
  Future<DatabaseEvent> getConversationId(String userId) {
    return _getChatSessionsRef()
        .orderByChild('user_id')
        .equalTo(userId)
        .limitToFirst(1)
        .once();
  }

  /// Get all users.
  Stream<DatabaseEvent> getChatRooms() {
    return _getChatUsersRef().orderByChild('last_online').onValue;
  }

  /// Create a new chat session.
  Future<void> createConversation(String conversationId, Map data) {
    return _getChatSessionsRef().child(conversationId).set(data);
  }

  /// Get a chat session from conversation id.
  Stream<DatabaseEvent> getConversation(String conversationId) {
    return _getChatSessionsRef().child(conversationId).onValue;
  }

  /// Delete chat session from conversation id.
  Future<void> deleteConversation(String conversationId) {
    return _getChatSessionsRef().child(conversationId).remove();
  }

  /// Create a new user id.
  String createNewUserId() {
    return _getChatUsersRef().push().key ?? '';
  }

  /// Update or create a user
  Future<void> updateOrCreateUser(String userId, Map data) {
    return _getChatUsersRef().child(userId).set(data);
  }

  /// Get a user from user id.
  Future<DatabaseEvent> getUser(String userId) {
    return _getChatUsersRef().child(userId).once();
  }

  /// Delete user by id.
  Future<void> deleteUser(String userId) {
    return _getChatUsersRef().child(userId).remove();
  }

  /// Get all chat messages from conversation id.
  Stream<DatabaseEvent> getChatMessages(String conversationId) {
    return _getChatMessagesRef()
        .orderByChild('conversation_id')
        .equalTo(conversationId)
        .onValue;
  }

  /// Send a chat message.
  Future<void> createChatMessage(Map data) {
    return _getChatMessagesRef().push().set(data);
  }

  /// Delete chat message.
  Future<void> deleteMessage(String messageId) {
    return _getChatMessagesRef().child(messageId).remove();
  }

  /// Update typing status.
  Future<void> updateTypingStatus(
    String conversationId,
    bool isTyping,
    String userId,
    String userName,
  ) {
    if (isTyping) {
      return _getChatSessionsRef()
          .child(conversationId)
          .child('typing')
          .child(userId)
          .set(userName);
    }

    return _getChatSessionsRef()
        .child(conversationId)
        .child('typing')
        .child(userId)
        .remove();
  }
}
