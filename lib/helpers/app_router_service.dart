import 'dart:async';

import 'package:flutter/material.dart';

/// Centralizes app-wide navigator access using Flutter's standard navigator key.
class AppRouter {
  AppRouter._();

  /// Navigator key attached to the root [MaterialApp].
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Returns the current root navigator state when available.
  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Returns the current root navigator context when available.
  static BuildContext? get context => navigatorKey.currentContext;

  /// Waits until the root navigator becomes available.
  static Future<NavigatorState> _waitForNavigator() {
    final NavigatorState? currentNavigator = navigator;
    if (currentNavigator != null) {
      return Future<NavigatorState>.value(currentNavigator);
    }

    final Completer<NavigatorState> completer = Completer<NavigatorState>();

    void checkNavigator(Duration _) {
      final NavigatorState? readyNavigator = navigator;
      if (readyNavigator != null) {
        completer.complete(readyNavigator);
      } else {
        WidgetsBinding.instance.addPostFrameCallback(checkNavigator);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(checkNavigator);
    return completer.future;
  }

  /// Pushes a named route onto the root navigator stack.
  static Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) async {
    final NavigatorState readyNavigator = await _waitForNavigator();
    return readyNavigator.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replaces the current route with the named route.
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) async {
    final NavigatorState readyNavigator = await _waitForNavigator();
    return readyNavigator.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Clears the stack and pushes the named route.
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    final NavigatorState readyNavigator = await _waitForNavigator();
    return readyNavigator.pushNamedAndRemoveUntil<T>(
      routeName,
      (Route<dynamic> _) => false,
      arguments: arguments,
    );
  }
}
