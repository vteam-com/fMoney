import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/*
  For this to work you have to include 

  dependencies:
    shared_preferences: ^2.5.3
    window_manager: ^0.5.0

*/

/// Represents my window manager.
class MyWindowManager extends WindowListener {
  static void setupMainWindow() async {
    if (!kIsWeb) {
      // Enable Impeller for better performance
      // This reduces shader compilation jank on mobile platforms
      if (Platform.isIOS || Platform.isAndroid) {
        // Impeller is enabled by default on iOS, but we can explicitly set it
        // For Android, we need to opt-in
        PlatformDispatcher.instance.onError =
            (
              final Object error,
              final StackTrace _,
            ) {
              // Log any Impeller-related errors
              if (kDebugMode) {
                print('Unhandled error: $error');
              }
              return true;
            };
        // Only enable system UI mode for iOS/Android.
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        await windowManager.ensureInitialized();

        // Tell window_manager we want to intercept close
        await windowManager.setPreventClose(true);

        windowManager.addListener(MyWindowManager());

        await MyWindowManager.restoreWindowState();
      }
    }
  }

  static Future<void> saveWindowState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Rect bounds = await windowManager.getBounds();

    await prefs.setDouble('window_x', bounds.left);
    await prefs.setDouble('window_y', bounds.top);
    await prefs.setDouble('window_width', bounds.width);
    await prefs.setDouble('window_height', bounds.height);
  }

  static Future<void> restoreWindowState() async {
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

      await windowManager.setBounds(Rect.fromLTWH(x, y, width, height));
    } else {
      // Optional: set a default window size
      await windowManager.setSize(const Size(800, 600));
      await windowManager.center();
    }

    await windowManager.show();
    await windowManager.focus();
  }

  static double? getSafeDouble(
    final SharedPreferences prefs,
    final String key,
  ) {
    final Object? value = prefs.get(key);
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble(); // gracefully convert
    }
    return null;
  }

  @override
  void onWindowClose() async {
    final bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      // Prevent the close, do your save logic first
      await saveWindowState();

      // Then actually destroy the window
      await windowManager.destroy();
    }
  }

  static void setAppWindowSize(final double width, final double height) {
    windowManager.ensureInitialized().then((void _) {
      final WindowOptions windowOptions = WindowOptions(
        size: Size(width, height),
        maximumSize: Size(width, height),
        center: true,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'fMoney by vTeam',
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    });
  }
}
