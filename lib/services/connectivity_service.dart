import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/game_2d_button.dart';
import '../widgets/game_2d_text.dart';

/// Service managing real-time internet connectivity verification.
/// Strictly enforces that online multiplayer (1v1 & 2v2) cannot be accessed
/// when the user has no internet connection.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();
  factory ConnectivityService() => instance;

  ConnectivityService._internal() {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      _testOverride = true;
      _isOnline = true;
      return;
    }
    // Initial connectivity check
    checkInternetAccess();
    // Periodic background check every 6 seconds
    _startPeriodicMonitoring();
  }

  bool _isOnline = true;
  bool get isOnline => _testOverride ?? _isOnline;

  bool? _testOverride;
  void setTestOnlineOverride(bool? override) {
    _testOverride = override;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    if (override != null) {
      _isOnline = override;
      isOnlineNotifier.value = override;
      notifyListeners();
    }
  }

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  Timer? _monitorTimer;
  bool _isChecking = false;

  void _startPeriodicMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      checkInternetAccess();
    });
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  /// Actively tests real internet reachability via DNS lookup to public DNS/Firebase endpoints.
  Future<bool> checkInternetAccess() async {
    if (_testOverride != null) {
      _isOnline = _testOverride!;
      isOnlineNotifier.value = _testOverride!;
      return _isOnline;
    }
    if (_isChecking) return _isOnline;
    _isChecking = true;

    bool connected = false;
    try {
      if (kIsWeb) {
        // In Flutter Web, browser handles online status
        connected = true;
      } else {
        // Attempt DNS lookups with strict timeout
        final result = await InternetAddress.lookup('dns.google')
            .timeout(const Duration(milliseconds: 2500));
        connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (_) {
      try {
        // Secondary fallback check to Firebase endpoint
        final fallback = await InternetAddress.lookup('firebase.google.com')
            .timeout(const Duration(milliseconds: 2500));
        connected = fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        connected = false;
      }
    } finally {
      _isChecking = false;
    }

    if (_isOnline != connected) {
      _isOnline = connected;
      isOnlineNotifier.value = connected;
      notifyListeners();
    }

    return _isOnline;
  }

  /// Strictly verifies internet access.
  /// If offline, displays a retro arcade warning modal blocking access to the online game.
  /// Returns `true` if internet is available, `false` if blocked.
  Future<bool> requireInternetAccess(BuildContext context) async {
    // First, run a fresh check to ensure status is up to date
    final bool available = await checkInternetAccess();
    if (available) return true;

    if (!context.mounted) return false;

    // Show styled arcade offline blocking dialog
    final bool? rechecked = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return const _NoInternetArcadeDialog();
      },
    );

    return rechecked ?? false;
  }
}

/// Arcade-styled blocking dialog displayed when trying to access online mode without internet
class _NoInternetArcadeDialog extends StatefulWidget {
  const _NoInternetArcadeDialog();

  @override
  State<_NoInternetArcadeDialog> createState() => _NoInternetArcadeDialogState();
}

class _NoInternetArcadeDialogState extends State<_NoInternetArcadeDialog> {
  bool _isRetrying = false;
  String? _errorMessage;

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });

    final online = await ConnectivityService.instance.checkInternetAccess();

    if (!mounted) return;

    if (online) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isRetrying = false;
        _errorMessage = 'Still offline. Please check your Wi-Fi or cellular data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Warning Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent, width: 2),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.redAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),

            // Arcade Title
            const Game2DText(
              'NO INTERNET CONNECTION',
              textColor: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
            const SizedBox(height: 10),

            // Description
            const Text(
              'Online 1v1 and 2v2 multiplayer requires an active internet connection to access Firebase battle rooms and match with other players.\n\nPlease connect to Wi-Fi or mobile data to proceed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Game2DButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    text: 'PLAY OFFLINE',
                    variant: GameButtonVariant.dark,
                    size: GameButtonSize.small,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Game2DButton(
                    onPressed: _isRetrying ? null : _handleRetry,
                    text: _isRetrying ? 'CHECKING...' : 'RETRY',
                    variant: GameButtonVariant.cyan,
                    size: GameButtonSize.small,
                    icon: _isRetrying ? Icons.sync : Icons.refresh_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
