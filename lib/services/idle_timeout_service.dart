import 'package:flutter/material.dart';

import 'session_manager.dart';

/// Auto-expires the logged-in user's session once the app has sat
/// backgrounded (another app opened, home button pressed, screen locked,
/// etc.) for [timeout] — mirroring "log me out if I close the app and
/// don't come back for a while". Deliberately does NOT expire on
/// in-app inactivity: as long as the app stays foregrounded, the
/// session stays alive no matter how long the user goes without
/// touching the screen (e.g. reading a long notice). Runs for the
/// lifetime of the app (started once from `main.dart`'s root widget);
/// harmless/no-op whenever there's no active session to expire.
class IdleTimeoutService with WidgetsBindingObserver {
  IdleTimeoutService._();
  static final IdleTimeoutService instance = IdleTimeoutService._();

  /// How long the app can sit backgrounded before the session is
  /// force-expired. A single named constant so the expiry message can
  /// quote the same number back to the user.
  static const Duration timeout = Duration(minutes: 3);

  DateTime? _backgroundedAt;
  bool _started = false;

  /// Call once, from the app root's `initState`.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Only the first of these per background stretch should record
        // the start time — inactive fires briefly on its own even when
        // the app stays foregrounded (e.g. a permission dialog).
        _backgroundedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt != null && DateTime.now().difference(backgroundedAt) >= timeout) {
          _onTimeout();
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _onTimeout() async {
    if (!await SessionManager.instance.hasSession()) return;
    final minutes = timeout.inMinutes;
    await SessionManager.instance.handleSessionExpired(
      reason: 'Your session has expired after being closed for $minutes minute${minutes == 1 ? '' : 's'}. Please log in again.',
    );
  }
}
