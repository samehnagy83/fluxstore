import 'package:firebase_core/firebase_core.dart';
import 'package:flux_interface/flux_interface.dart';
import 'package:inspireui/inspireui.dart';

extension FluxFirebaseOptionExtension on FluxFirebaseOption {
  FirebaseOptions? toFirebaseOptions() {
    if (isValid) {
      return FirebaseOptions(
        apiKey: apiKey!,
        appId: appId!,
        projectId: projectId!,
        messagingSenderId: messagingSenderId!,
        storageBucket: storageBucket,
        databaseURL: databaseURL,
        authDomain: authDomain,
        measurementId: measurementId,
        iosClientId: iosClientId,
        iosBundleId: iosBundleId,
        androidClientId: androidClientId,
      );
    }

    return null;
  }
}

extension SupabaseConfigOptionExtension on FirebaseOptions {
  FluxFirebaseOption toFluxFirebaseOption() {
    return FluxFirebaseOption(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: messagingSenderId,
      storageBucket: storageBucket,
      databaseURL: databaseURL,
      authDomain: authDomain,
      measurementId: measurementId,
      iosClientId: iosClientId,
      iosBundleId: iosBundleId,
      androidClientId: androidClientId,
    );
  }
}

extension FirebaseFactoryExt on Firebase {
  static Future<FirebaseApp> initializeApp({
    String? name,
    FirebaseOptions? options,
    String? demoProjectId,
  }) async {
    try {
      // Determine the app name to use (null means default app)
      final appName = name?.isNotEmpty == true ? name : null;

      // Check if app already exists
      try {
        if (appName != null) {
          // Check for named app
          final isExistApp = Firebase.apps.any((app) => app.name == appName);
          if (isExistApp) {
            printLog(
                '[Firebase] App "$appName" already exists, returning existing instance');
            return Firebase.app(appName);
          }
        } else {
          // Check for default app
          final hasDefaultApp =
              Firebase.apps.any((app) => app.name == '[DEFAULT]');
          if (hasDefaultApp) {
            printLog(
                '[Firebase] Default app already exists, returning existing instance');
            return Firebase.app(); // Returns default app
          }
        }
      } catch (e) {
        // Log error for debugging but continue with initialization
        printLog(
            '[Firebase] Failed to check existing app: ${appName ?? '[DEFAULT]'}. Error: $e');
      }

      // Try to initialize with full options first
      try {
        return await Firebase.initializeApp(
          name: appName,
          options: options,
          demoProjectId: demoProjectId,
        );
      } catch (e) {
        // Check if this is the "already exists" error
        if (e.toString().contains('already exists')) {
          printLog(
              '[Firebase] App already exists during initialization, attempting to return existing app');
          try {
            return appName != null ? Firebase.app(appName) : Firebase.app();
          } catch (getAppError) {
            printLog(
                '[Firebase] Failed to get existing app after "already exists" error: $getAppError');
            rethrow;
          }
        }

        printLog(
            '[Firebase] Failed to initialize with full options. Error: $e');

        // If demoProjectId is provided, try fallback to demo mode
        if (demoProjectId != null) {
          try {
            return await Firebase.initializeApp(
              name: appName,
              options: options?.copyWith(projectId: demoProjectId) ??
                  FirebaseOptions(
                    apiKey: 'demo-api-key',
                    appId: 'demo-app-id',
                    messagingSenderId: 'demo-sender-id',
                    projectId: demoProjectId,
                  ),
            );
          } catch (demoError) {
            // Check if demo initialization also has "already exists" error
            if (demoError.toString().contains('already exists')) {
              printLog(
                  '[Firebase] Demo app already exists, returning existing app');
              try {
                return appName != null ? Firebase.app(appName) : Firebase.app();
              } catch (getAppError) {
                printLog(
                    '[Firebase] Failed to get existing demo app: $getAppError');
                rethrow;
              }
            }
            printLog(
                '[Firebase] Failed to initialize in demo mode. Error: $demoError');
            rethrow;
          }
        } else if (appName?.isNotEmpty ?? false) {
          // Try without name as fallback
          try {
            return await Firebase.initializeApp(options: options);
          } catch (fallbackError) {
            if (fallbackError.toString().contains('already exists')) {
              printLog(
                  '[Firebase] Fallback app already exists, returning default app');
              return Firebase.app();
            }
            rethrow;
          }
        }

        // If no demoProjectId available, rethrow original error
        rethrow;
      }
    } catch (e) {
      printLog('[Firebase] Fatal error during initialization: $e');
      rethrow;
    }
  }
}
