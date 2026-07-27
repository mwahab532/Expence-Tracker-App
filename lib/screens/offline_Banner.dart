import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/providers/Network_conectivity_provider.dart';
import 'package:provider/provider.dart';

/// Wraps any screen and shows a thin banner at the top when offline, plus
/// a one-time snackbar at the moment connection is lost or restored.
/// Writes still queue locally via Firestore's offline persistence and
/// sync automatically once back online — this widget just makes that
/// state visible instead of silent.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool? _previousStatus;

  void _handleStatusChange(bool isOnline) {
    // Only fire on an actual transition, not on every rebuild — and skip
    // the very first read (app startup), so there's no spurious "back
    // online" snackbar the instant the app opens.
    if (_previousStatus == null) {
      _previousStatus = isOnline;
      return;
    }
    if (_previousStatus == isOnline) return;
    _previousStatus = isOnline;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,

          content: Text(
            isOnline
                ? 'Back online — syncing changes'
                : ' Device has no internet connection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          backgroundColor: isOnline
              ? Colors.green.shade700
              : Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    _handleStatusChange(isOnline);

    return Column(children: [Expanded(child: widget.child)]);
  }
}
