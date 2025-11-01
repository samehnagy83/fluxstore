import 'package:flux_localization/flux_localization.dart';
import 'package:fstore/common/tools/gravatar.dart';
import 'package:fstore/data/boxes.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../constants/keys.dart';

class ChatUser {
  final String? id;
  final String? email;
  final String? name;
  final int unread;
  final DateTime? lastActive;
  final bool? isOnline;
  final String? languageCode;
  final String? pushToken;
  final bool isTyping;
  final List<String> blackList;
  final String? avatarImage;
  final String? vendorId;
  final String? vendorName;

  ChatUser({
    this.id,
    this.email,
    this.name,
    this.unread = 0,
    this.lastActive,
    this.isOnline,
    this.languageCode,
    this.pushToken,
    this.isTyping = false,
    this.blackList = const [],
    this.avatarImage,
    this.vendorId,
    this.vendorName,
  });

  factory ChatUser.fromFirestoreJson(Map json) {
    final lastActive = json[kFirestoreFieldLastActive] != null
        ? DateTime.tryParse('${json[kFirestoreFieldLastActive]}')
        : null;

    final onlineStatus = lastActive != null &&
        lastActive.toLocal().isAfter(
              DateTime.now().subtract(
                const Duration(minutes: 5),
              ),
            );

    final image = '${json[kFirestoreFieldImage]}'.isNotEmpty
        ? json[kFirestoreFieldImage]
        : null;

    return ChatUser(
      // Use email as id for Firestore for backward compatibility
      id: json[kFirestoreFieldEmail],
      email: json[kFirestoreFieldEmail],
      name: json[kFirestoreFieldName],
      avatarImage: image,
      unread: json[kFirestoreFieldUnread] ?? 0,
      lastActive: lastActive,
      isOnline: onlineStatus,
      languageCode: json[kFirestoreFieldLanguageCode],
      pushToken: json[kFirestoreFieldPushToken],
      isTyping: json[kFirestoreFieldIsTyping] ?? false,
      blackList: List<String>.from(json[kFirestoreFieldBlackList] ?? []),
    );
  }

  Map<String, dynamic> toFirestoreJson() => {
        kFirestoreFieldEmail: email,
        kFirestoreFieldName: name,
        kFirestoreFieldImage: avatarImage,
        kFirestoreFieldUnread: unread,
        kFirestoreFieldLastActive: lastActive?.toUtc().toIso8601String(),
        kFirestoreFieldLanguageCode: languageCode,
        kFirestoreFieldPushToken: pushToken,
        kFirestoreFieldIsTyping: isTyping,
        kFirestoreFieldBlackList: blackList,
      };

  factory ChatUser.fromRealtimeJson(Map json) {
    final lastActive = int.tryParse('${json['last_online']}');
    final onlineStatus = json['status'] == 'online'
        ? true
        : json['status'] == 'offline'
            ? false
            : null;
    final image =
        '${json['avatar_image']}'.isNotEmpty ? json['avatar_image'] : null;

    return ChatUser(
      id: json['user_id'],
      email: json['user_email'],
      name: json['user_name'],
      unread: 0,
      lastActive: lastActive != null
          ? DateTime.fromMillisecondsSinceEpoch(lastActive)
          : null,
      isOnline: onlineStatus,
      languageCode: null,
      pushToken: json['push_token'],
      isTyping: false,
      blackList: [],
      avatarImage: image,
      vendorId: json['vendor_id']?.toString(),
      vendorName: json['vendor_name'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatUser &&
          id == other.id &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          name == other.name &&
          unread == other.unread &&
          languageCode == other.languageCode &&
          pushToken == other.pushToken &&
          lastActive == other.lastActive &&
          isOnline == other.isOnline &&
          isTyping == other.isTyping &&
          blackList == other.blackList &&
          avatarImage == other.avatarImage &&
          vendorId == other.vendorId &&
          vendorName == other.vendorName;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      name.hashCode ^
      unread.hashCode ^
      lastActive.hashCode ^
      isOnline.hashCode ^
      languageCode.hashCode ^
      isTyping.hashCode ^
      blackList.hashCode ^
      avatarImage.hashCode ^
      vendorId.hashCode ^
      vendorName.hashCode;

  ChatUser copyWith({
    String? id,
    String? email,
    String? name,
    int? unread,
    DateTime? lastActive,
    bool? isOnline,
    String? languageCode,
    String? pushToken,
    bool? isTyping,
    List<String>? blackList,
    String? avatarImage,
    String? vendorId,
    String? vendorName,
  }) {
    return ChatUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      unread: unread ?? this.unread,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
      languageCode: languageCode ?? this.languageCode,
      pushToken: pushToken ?? this.pushToken,
      isTyping: isTyping ?? this.isTyping,
      blackList: blackList ?? this.blackList,
      avatarImage: avatarImage ?? this.avatarImage,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
    );
  }
}

extension ChatUserExtension on ChatUser {
  String? get displayName => (name?.isNotEmpty ?? false)
      ? name!
      : (email?.isNotEmpty ?? false)
          ? email
          : null;

  bool get isActive => isOnline == true;

  bool get isLongTimeAgo =>
      isOnline == false &&
      lastActive != null &&
      lastActive!.toLocal().isBefore(
            DateTime.now().subtract(
              const Duration(days: 1),
            ),
          );

  bool get isActiveNa =>
      isOnline == null ||
      lastActive == null ||
      lastActive!.millisecondsSinceEpoch <= 0;

  String? displayLastActive(S locale) {
    if (isActiveNa) {
      return null;
    }
    if (isActive) {
      return locale.activeNow;
    }
    if (isLongTimeAgo) {
      return locale.activeLongAgo;
    }
    return locale.activeFor(timeago.format(
      lastActive!,
      locale: SettingsBox().languageCode,
    ));
  }

  String get avatarImageUrl => avatarImage ?? getGravatarUrl(email);

  bool isSameUser({String? email, String? id, ChatUser? user}) {
    if (id != null && id == this.id) {
      return true;
    }

    if (email != null && email == this.email) {
      return true;
    }

    if (user != null) {
      return isSameUser(email: user.email, id: user.id);
    }

    return false;
  }

  bool get isInvalid => email == null && id == null;
}
