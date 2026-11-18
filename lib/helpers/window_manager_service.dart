import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:money/helpers/app_logger_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/*
  For this to work you have to include 

  dependencies:
    shared_preferences: ^2.5.3
    window_manager: ^0.7.0

*/

/// Represents my window manager.
abstract final class MyWindowManager {
  /// Keeps the exit-request lifecycle listener alive for the app's lifetime.
  static AppLifecycleListener? _lifecycleListener;

  /// True once the app-exit handshake has saved state and approved termination.
  static bool _isExiting = false;

  /// Asked before the window closes or the app quits; returning false keeps the app open
  /// (e.g. the user cancelled the unsaved-changes prompt).
  static Future<bool> Function() confirmClose = () async => true;

  /// The app's native window, or null when the platform has none yet.
  static Window? get _window => WindowManager.instance.getCurrent();

  /// Sets up main window with platform-specific optimizations.
  static Future<void> setupMainWindow() async {
    if (!kIsWeb) {
      // Enable Impeller for better performance
      // This reduces shader compilation jank on mobile platforms
      if (Platform.isIOS || Platform.isAndroid) {
        // Impeller is enabled by default on iOS, but we can explicitly set it
        // For Android, we need to opt-in
        PlatformDispatcher.instance.onError =
            (
              Object error,
              StackTrace stackTrace,
            ) {
              AppLogger.error(
                module: 'window_manager_service',
                operation: 'platformDispatcher.onError',
                error: error,
                stackTrace: stackTrace,
              );
              return true;
            };
        // Only enable system UI mode for iOS/Android.
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        // Intercept close requests so the window bounds are saved first.
        _window?.addListener(_onWindowEvent);

        // Handle Cmd-Q / OS-initiated quit through Flutter's cooperative exit
        // handshake: save state while the engine is still alive, then let the
        // termination proceed normally.
        _lifecycleListener ??= AppLifecycleListener(onExitRequested: _onExitRequested);

        await MyWindowManager.restoreWindowState();
      }
    }
  }

  /// Quits the app as closing its window does: asks about unsaved changes, runs [beforeQuit],
  /// saves the window state, then exits. Returns false, leaving the app open, when the user cancels.
  /// If [beforeQuit] throws, the error propagates and the app stays open.
  static Future<bool> quitApp({required Future<void> Function() beforeQuit}) async {
    if (!await confirmClose()) {
      return false;
    }
    await beforeQuit();
    // already confirmed: the close and exit requests that follow must not ask again
    _isExiting = true;
    await saveWindowState();
    await ServicesBinding.instance.exitApplication(AppExitType.required);
    return true;
  }

  /// Saves current window state to shared preferences.
  static Future<void> saveWindowState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Window? window = _window;
    if (window == null) {
      return;
    }
    final Rect bounds = window.bounds.toRect();

    await prefs.setDouble('window_x', bounds.left);
    await prefs.setDouble('window_y', bounds.top);
    await prefs.setDouble('window_width', bounds.width);
    await prefs.setDouble('window_height', bounds.height);
  }

  /// Restores window state from shared preferences.
  static Future<void> restoreWindowState() async {
    final Window? window = _window;
    if (window == null) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool hasData =
        prefs.containsKey('window_x') &&
        prefs.containsKey('window_y') &&
        prefs.containsKey('window_width') &&
        prefs.containsKey('window_height');

    if (hasData) {
      final double x = MyWindowManager.getSafeDouble(prefs, 'window_x')!;
      final double y = MyWindowManager.getSafeDouble(prefs, 'window_y')!;
      final double width = MyWindowManager.getSafeDouble(prefs, 'window_width')!;
      final double height = MyWindowManager.getSafeDouble(prefs, 'window_height')!;

      window.bounds = Rect.fromLTWH(x, y, width, height).toNative();
    } else {
      // Optional: set a default window size
      window.setSize(
        const Size(
          SizeForWindow.desktopWidth,
          SizeForWindow.desktopHeight,
        ).toNative(),
        false,
      );
      window.center();
    }

    window.show();
    window.focus();
  }

  /// Safely gets double value from shared preferences.
  static double? getSafeDouble(
    SharedPreferences prefs,
    String key,
  ) {
    final Object? value = prefs.get(key);
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble(); // gracefully convert
    }
    return null;
  }

  /// Holds a close request open until the window state is saved, then lets
  /// the window close.
  static Future<void> _onWindowEvent(WindowEvent event) async {
    // Once the exit handshake has saved state, let the terminate-driven close
    // proceed without touching an engine that is shutting down.
    if (event is! WindowCloseRequestedEvent || _isExiting) {
      return;
    }
    final EventDecision? decision = event.request.defer();
    if (!await confirmClose()) {
      decision?.cancel();
      return;
    }
    // already confirmed: the exit request that may follow must not ask again
    _isExiting = true;
    await saveWindowState();
    decision?.accept();
  }

  /// Saves window state during the app-exit handshake (Cmd-Q, OS quit) while
  /// the engine is still alive, then allows the termination to proceed.
  static Future<AppExitResponse> _onExitRequested() async {
    if (!_isExiting && !await confirmClose()) {
      return AppExitResponse.cancel;
    }
    await saveWindowState();

    // Let the OS close the window during termination without the
    // close interception firing on a dying engine.
    _isExiting = true;

    return AppExitResponse.exit;
  }

  /// Sets the application window size.
  static void setAppWindowSize(double width, double height) {
    final Window? window = _window;
    if (window == null) {
      return;
    }
    final Size size = Size(width, height);
    window
      ..setSize(size.toNative(), false)
      ..maximumSize = size.toNative()
      ..center()
      ..isVisibleInTaskbar = true
      ..titleBarStyle = TitleBarStyle.normal
      ..title = SharedStrings.appWindowTitle
      ..show()
      ..focus();
  }
}
