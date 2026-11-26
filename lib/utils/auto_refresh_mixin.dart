import 'dart:async';

import 'package:flutter/material.dart';

/// Polls the backend on a fixed interval so a screen's data stays close
/// to real-time with whatever the web portal shows, without the backend
/// needing to support WebSockets/push (it doesn't).
///
/// Mix into any `State` *together with* [WidgetsBindingObserver]
/// (`with WidgetsBindingObserver, AutoRefreshMixin` — in that order, so
/// this mixin's [didChangeAppLifecycleState] wins), call
/// [startAutoRefresh] once (from `initState`, after the first manual
/// load) with the same fetch function already used there, and call
/// [disposeAutoRefresh] from `dispose`. Polling pauses while the app is
/// backgrounded so it doesn't burn data/battery on a screen nobody's
/// looking at, and refreshes immediately on return to foreground.
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoRefreshTimer;
  Future<void> Function()? _autoRefreshCallback;
  Duration _autoRefreshInterval = const Duration(seconds: 20);

  void startAutoRefresh(Future<void> Function() onRefresh, {Duration interval = const Duration(seconds: 20)}) {
    _autoRefreshCallback = onRefresh;
    _autoRefreshInterval = interval;
    _restartAutoRefreshTimer();
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void _restartAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (!mounted) return;
      _autoRefreshCallback?.call();
    });
  }

  @mustCallSuper
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_autoRefreshCallback != null) {
          // A short grace delay before the resume-triggered refetch: right
          // after an unlock the OS is often still reconnecting network, so
          // firing immediately can hit a transient failure. Waiting briefly
          // avoids flashing an error for a normal lock/unlock cycle.
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            _autoRefreshCallback?.call();
          });
          _restartAutoRefreshTimer();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _autoRefreshTimer?.cancel();
    }
  }

  @protected
  void disposeAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }
}
