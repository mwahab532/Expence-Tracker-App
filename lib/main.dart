import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // runZonedGuarded is the last line of defense: it catches anything that
  // escapes every try/catch in the app instead of letting it crash the
  // process silently with nothing but a console stack trace.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Route Flutter framework errors (widget build/layout errors) through
    // the same reporting path instead of just printing to console.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      // Hook a crash-reporting SDK here later (Crashlytics, Sentry, etc.):
      // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Catches errors from the platform side (native crashes surfaced to
    // Dart) that runZonedGuarded's zone alone wouldn't see.
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error');
      return true; // handled — prevents the default crash behavior
    };

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      runApp(const ExpenseTrackerApp());
    } catch (e, st) {

      debugPrint('Firebase.initializeApp failed: $e');
      debugPrint('$st');
      runApp(_StartupErrorApp(error: e));
    }
  }, (error, stack) {

    debugPrint('Uncaught zone error: $error');
    debugPrint('$stack');
  });
}

class _StartupErrorApp extends StatelessWidget {
  final Object error;
  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'The app failed to start',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
