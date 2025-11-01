import 'package:flux_firebase/impl/firebase_firestore/loyalty_firestore_service_impl.dart';
import 'package:flux_firebase/impl/firebase_notification_service.dart';
import 'package:flux_firebase/index.dart';
import 'package:flux_interface/flux_interface.dart';
import 'package:injectable/injectable.dart';

@module
abstract class FirebaseModule {
  @singleton
  FirebaseCoreService firebaseCoreService() => FirebaseCorePlatformImpl();

  @singleton
  BaseFirebaseServices baseFirebaseServices() => FirebaseServices();

  @singleton
  FirebaseMessagingService firebaseMessagingService() =>
      FirebaseMessagingServiceImpl();

  FirebaseNotificationService firebaseNotificationService() =>
      FirebaseNotificationServiceImpl();

  LoyaltyFirestoreService loyaltyFirestoreService() {
    final loyaltyService = LoyaltyFirestoreServiceImpl()
      ..setFirebaseApp(FirebaseServices().app);
    return loyaltyService;
  }
}
