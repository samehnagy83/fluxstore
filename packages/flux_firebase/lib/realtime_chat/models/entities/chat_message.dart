import 'package:fstore/common/tools/gravatar.dart';

import '../../constants/keys.dart';

class ChatMessage {
  final String sender;
  final String? senderName;
  final String? avatarImage;
  final DateTime createdAt;
  final String text;

  ChatMessage({
    this.sender = '',
    this.senderName,
    this.avatarImage,
    required this.createdAt,
    this.text = '',
  });

  factory ChatMessage.fromFirestoreJson(Map json) => ChatMessage(
        sender: json[kFirestoreFieldSender] ?? '',
        senderName: json[kFirestoreFieldName],
        avatarImage: json[kFirestoreFieldImage],
        createdAt: DateTime.tryParse('${json[kFirestoreFieldCreatedAt]}') ??
            DateTime.now(),
        text: json[kFirestoreFieldText] ?? '',
      );

  Map<String, dynamic> toFirestoreJson() => {
        kFirestoreFieldSender: sender,
        kFirestoreFieldCreatedAt: createdAt.toUtc().toIso8601String(),
        kFirestoreFieldText: text,
        kFirestoreFieldName: senderName,
        kFirestoreFieldImage: avatarImage,
      };

  factory ChatMessage.fromRealtimeJson(Map json) {
    final image =
        '${json['avatar_image']}'.isNotEmpty ? json['avatar_image'] : null;

    return ChatMessage(
      sender: json['user_id']?.toString() ?? '',
      senderName: json['user_name'],
      avatarImage: image,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['msg_time']),
      text: json['msg'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          sender == other.sender &&
          createdAt == other.createdAt &&
          senderName == other.senderName &&
          avatarImage == other.avatarImage &&
          text == other.text;

  @override
  int get hashCode =>
      sender.hashCode ^
      createdAt.hashCode ^
      text.hashCode ^
      senderName.hashCode ^
      avatarImage.hashCode;
}

extension ChatUserExtension on ChatMessage {
  String get displayName => senderName ?? sender;

  String get avatarImageUrl => avatarImage ?? getGravatarUrl(sender);
}
