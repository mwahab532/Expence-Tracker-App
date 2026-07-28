import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');

      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformDispatcher error: $error');
        return true; // handled — prevents the default crash behavior
      };
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        runApp(const ExpenseTrackerApp());
      } catch (e, st) {
        // If Firebase itself fails to initialize (bad config, first-launch
        // platform issue), show a real error screen instead of a blank
        // screen or an uncaught crash.
        debugPrint('Firebase.initializeApp failed: $e');
        debugPrint('$st');
        runApp(_StartupErrorApp(error: e));
      }
    },
    (error, stack) {
      // Anything that reaches here slipped past every other layer.
      debugPrint('Uncaught zone error: $error');
      debugPrint('$stack');
    },
  );
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