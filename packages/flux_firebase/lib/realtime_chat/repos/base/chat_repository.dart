import '../../models/entities/chat_message.dart';
import '../../models/entities/chat_room.dart';
import '../../models/entities/chat_user.dart';

abstract class ChatRepository {
  ChatUser get sender;

  Stream<List<ChatRoom>> getChatRooms(bool getAllChatRooms);

  Stream<ChatRoom?> getChatRoom(String roomId);

  Stream<List<ChatMessage>> getConversation(String chatId);

  Future<void> sendChatMessage(
    String chatId,
    String message,
  );

  Future<void> updateTypingStatus(
    String chatId, {
    bool? isTyping,
  });

  Future<void> updateChatRoom(
    String chatId, {
    String? latestMessage,
    int? receiverUnreadCountPlus,
  });

  Future<void> deleteChatRoom(String chatId);

  Future<String> getChatRoomId(ChatUser receiver);

  Future<void> updateBlackList(
    String chatId, {
    List<String>? blackList,
  });

  Future<void> exitChatRoom(String chatId);

  Future<void> exitChat();
}
