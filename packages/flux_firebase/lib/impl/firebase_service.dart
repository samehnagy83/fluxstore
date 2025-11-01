import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flux_interface/flux_interface.dart';
import 'package:fstore/common/config.dart';
import 'package:fstore/common/constants.dart';
import 'package:fstore/common/tools.dart';
import 'package:fstore/models/entities/user.dart';
import 'package:fstore/services/index.dart';

import '../firebase_service_factory.dart';
import '../realtime_chat/realtime_chat.dart';
import '../realtime_chat/wcfm_live_chat.dart';

class FirebaseServices extends BaseFirebaseServices {
  static final FirebaseServices _instance = FirebaseServices._internal();

  factory FirebaseServices() => _instance;

  FirebaseServices._internal();

  bool _isEnabled = false;

  FirebaseApp? _app;

  FirebaseApp get app => _app ?? Firebase.app();

  @override
  bool get isEnabled => _isEnabled;

  @override
  Future<void> init({FluxFirebaseOption? option, String? name}) async {
    var startTime = DateTime.now();
    await _app?.delete();
    _app = await FirebaseServiceFactory.create<FirebaseCoreService>()
        ?.initializeApp(
      option: option,
      name: name,
    );
    _isEnabled = kAdvanceConfig.enableFirebase;

    /// Not require Play Services
    /// https://firebase.google.com/docs/android/android-play-services
    _authService = FirebaseServiceFactory.createAuthService(app);

    if (kFirebaseAnalyticsConfig['enableFirebaseAnalytics'] == true) {
      _firebaseAnalytics = FirebaseServiceFactory.createAnalyticsService(app)!
        ..init(
          adStorageConsentGranted:
              kFirebaseAnalyticsConfig['adStorageConsentGranted'],
          analyticsStorageConsentGranted:
              kFirebaseAnalyticsConfig['analyticsStorageConsentGranted'],
          adPersonalizationSignalsConsentGranted: kFirebaseAnalyticsConfig[
              'adPersonalizationSignalsConsentGranted'],
          adUserDataConsentGranted:
              kFirebaseAnalyticsConfig['adUserDataConsentGranted'],
          functionalityStorageConsentGranted:
              kFirebaseAnalyticsConfig['functionalityStorageConsentGranted'],
          personalizationStorageConsentGranted:
              kFirebaseAnalyticsConfig['personalizationStorageConsentGranted'],
          securityStorageConsentGranted:
              kFirebaseAnalyticsConfig['securityStorageConsentGranted'],
        );
    } else {
      _firebaseAnalytics = FirebaseAnalyticsService()..init();
    }

    if (!kIsWeb) {
      _remoteConfigService = FirebaseServiceFactory.createRemoteServices(app);
    }

    /// Require Play Services
    const message = '[FirebaseServices] Init successfully';
    if (GmsCheck().isGmsAvailable) {
      _messaging = FirebaseMessaging.instance;
      printLog(message, startTime);
    } else {
      printLog('$message (without Google Play Services)', startTime);
    }
  }

  /// Firebase Cloud Firestore
  FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(app: app);

  /// Firebase Realtime Database
  FirebaseDatabase get database => FirebaseDatabase.instanceFor(app: app);

  FirebaseAuth get firebaseAuth => FirebaseAuth.instanceFor(app: app);

  /// Firebase Messaging
  FirebaseMessaging? _messaging;

  FirebaseMessaging? get messaging => _messaging;

  /// Firebase Auth
  FirebaseAuthService? _authService;

  FirebaseAuthService? get auth => _authService;

  /// Firebase Remote Config
  FirebaseRemoteServices? _remoteConfigService;

  FirebaseRemoteServices? get remoteConfig => _remoteConfigService;

  /// Firebase Analytics
  FirebaseAnalyticsService? _firebaseAnalytics;

  @override
  FirebaseAnalyticsService? get firebaseAnalytics => _firebaseAnalytics;

  @override
  void deleteAccount() {
    _messaging?.deleteToken();
    _authService?.deleteAccount();
  }

  @override
  Future<void> loginFirebaseApple({authorizationCode, identityToken}) async {
    if (FirebaseServices().isEnabled) {
      await _authService?.loginFirebaseApple(
          authorizationCode: authorizationCode, identityToken: identityToken);
    }
  }

  @override
  Future<void> loginFirebaseFacebook({token, rawNonce}) async {
    if (FirebaseServices().isEnabled) {
      await _authService?.loginFirebaseFacebook(
          token: token, rawNonce: rawNonce);
    }
  }

  @override
  Future<void> loginFirebaseGoogle({token}) async {
    if (FirebaseServices().isEnabled) {
      await _authService?.loginFirebaseGoogle(token: token);
    }
  }

  @override
  Future<void> loginFirebaseEmail({email, password}) async {
    if (FirebaseServices().isEnabled) {
      await _authService?.loginFirebaseEmail(email: email, password: password);
    }
  }

  @override
  Future<User?>? loginFirebaseCredential({credential}) {
    return _authService!.loginFirebaseCredential(credential: credential);
  }

  @override
  void saveUserToFirestore({User? user}) async {
    final token = await messaging?.getToken();
    printLog('token: $token');
    final docPath = (user?.email?.isNotEmpty ?? false) ? user?.email : user?.id;
    await firestore.collection('users').doc(docPath).set(
      {'deviceToken': token, 'isOnline': true},
      SetOptions(merge: true),
    );
    if (GmsCheck().isGmsAvailable) {
      try {
        await Services()
            .api
            .updateUserInfo({'deviceToken': token}, user!.cookie);
      } catch (err, trace) {
        printError(err, trace);
      }
    }
  }

  @override
  dynamic getFirebaseCredential({verificationId, smsCode}) {
    return _authService?.getFirebaseCredential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  StreamController<String?>? getFirebaseStream() {
    return _authService!.getFirebaseStream();
  }

  @override
  Future<void> verifyPhoneNumber({
    phoneNumber,
    codeAutoRetrievalTimeout,
    codeSent,
    required void Function(String?) verificationCompleted,
    void Function(FirebaseErrorException error)? verificationFailed,
    forceResendingToken,
    Duration? timeout,
  }) async {
    await _authService!.verifyPhoneNumber(
      phoneNumber: phoneNumber!,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      codeSent: codeSent,
      timeout: timeout ?? const Duration(seconds: 120),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      forceResendingToken: forceResendingToken,
    );
  }

  @override
  Widget renderChatScreen({
    required String? senderEmail,
    required String? senderName,
    String? receiverEmail,
    String? receiverName,
    String? initMessage,
  }) {
    final isMvApp =
        ServerConfig().isVendorType() || ServerConfig().isVendorManagerType();

    if (senderEmail == null) {
      return const ChatAuth();
    }

    final sender = ChatUser(
      email: senderEmail,
      name: senderName,
    );
    final receiver = receiverEmail != null
        ? ChatUser(
            email: receiverEmail,
            name: receiverName,
          )
        : null;
    final admin = ChatUser(
      email: kConfigChat.realtimeChatConfig.adminEmail,
      name: kConfigChat.realtimeChatConfig.adminName,
    );

    // Will open the chat list if it is a MultiVendor app, then open the chat
    // screen if the receiver is specific
    if (sender.isSameUser(user: admin) ||
        sender.isSameUser(user: receiver) ||
        isMvApp) {
      return RealtimeChat(
        chatArgs: ChatArgs(
          type: RealtimeChatType.userToUsers,
          sender: sender,
          receiver: sender.isSameUser(user: receiver)
              ? null
              : receiver, // If the user is chatting by himself, it will just open the chat list.
          admin: admin,
          initMessage: initMessage,
        ),
      );
    }

    // Otherwise, user chat with Admin as default
    return RealtimeChat(
      chatArgs: ChatArgs(
        type: RealtimeChatType.userToUser,
        sender: sender,
        receiver: receiver,
        admin: admin,
        initMessage: initMessage,
      ),
    );
  }

  @override
  Widget renderWcfmLiveChatScreen({
    required String? senderId,
    required String? senderName,
    required String? senderEmail,
    required bool? senderIsVendor,
    String? receiverId,
    String? receiverEmail,
    String? receiverName,
    String? initMessage,
  }) {
    // If the sender is just a customer, only chat with vendor or admin
    // Will open the chat screen if the receiver is specific and is not sender
    final isReceiverSpecific = receiverId != null && senderId != receiverId;
    final isCustomerChat = senderIsVendor != true || isReceiverSpecific;

    final vendorId = isReceiverSpecific
        ? receiverId
        : isCustomerChat
            ? '0'
            : senderId;
    final vendorName = isReceiverSpecific
        ? receiverName ?? ''
        : isCustomerChat
            ? kConfigChat.realtimeChatConfig.adminName
            : senderName;

    final sender = ChatUser(
      id: senderId,
      email: senderEmail,
      name: senderName,
      vendorId: vendorId,
      vendorName: vendorName,
    );

    final receiver = receiverId != null
        ? ChatUser(
            id: receiverId,
            email: receiverEmail,
            name: receiverName,
            vendorId: vendorId,
            vendorName: vendorName,
          )
        : null;

    final admin = ChatUser(
      id: '0',
      name: kConfigChat.realtimeChatConfig.adminName,
      vendorId: '0',
      vendorName: kConfigChat.realtimeChatConfig.adminName,
    );

    if (isCustomerChat) {
      return WCFMLiveChat(
        chatArgs: ChatArgs(
          type: RealtimeChatType.userToUser,
          sender: sender,
          receiver: receiver,
          admin: admin,
          initMessage: initMessage,
          isWcfmLiveChat: true,
        ),
      );
    }

    // Vendor/Admin chatting to multiple users or himself
    return WCFMLiveChat(
      chatArgs: ChatArgs(
        type: RealtimeChatType.userToUsers,
        sender: sender,
        receiver: sender.isSameUser(user: receiver)
            ? null
            : receiver, // If the user is chatting by himself, it will just open the chat list.
        admin: sender,
        initMessage: initMessage,
        isWcfmLiveChat: true,
      ),
    );
  }

  @override
  Future<void> createUserWithEmailAndPassword({email, password}) async {
    if (isEnabled) {
      await _authService?.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  @override
  String? getCurrentUserId() {
    return _authService?.getCurrentUserId();
  }

  @override
  Future<String?> getMessagingToken() async {
    return await messaging?.getToken();
  }

  @override
  Future<bool> loadRemoteConfig() {
    return _remoteConfigService?.loadRemoteConfig() ?? Future.value(false);
  }

  @override
  Future<List<String>> getRemoteKeys() async {
    return await _remoteConfigService?.getKeys() ?? [];
  }

  @override
  String getRemoteConfigString(String key) {
    return _remoteConfigService?.getString(key) ?? '';
  }

  @override
  Future<void> signOut() async {
    if (isEnabled) {
      _authService?.signOut();
    }
  }

  @override
  List<NavigatorObserver> getMNavigatorObservers() {
    return firebaseAnalytics?.getMNavigatorObservers() ?? <NavigatorObserver>[];
  }

  @override
  Future<String?>? getIdToken() {
    return _authService?.getIdToken();
  }
}
