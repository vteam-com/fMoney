// ignore: fcheck_dead_code
import 'package:flutter/scheduler.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_router.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/pure/theme_custom.dart';

const int _defaultDurationSeconds = 5;
const int _persistDurationDays = 1;
const double _titleFontSize = 14;
const double _messageFontSize = 13;
const double _contentSpacing = 4;
const double _snackBarMargin = 8;
const double _snackBarBorderRadius = 8;
const double _snackBarElevation = 6;
const int _retryDelayMs = 100;

/// Global snackbar service that works without BuildContext.
/// Uses Flutter 3.38.0 Material snackbar improvements with custom overlay management.
/// Supports multiple concurrent snackbars, better accessibility, and testability.
class SnackBarService {
  static final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  // For testing: allow injection of custom scaffold messenger state
  static ScaffoldMessengerState? _testScaffoldMessengerState;

  // Testing mode - skip showing snackbars in integration tests
  static bool _testingMode = false;

  // Queue to manage multiple snackbars
  static final List<_QueuedSnackBar> _queue = <_QueuedSnackBar>[];
  static bool _flushScheduled = false;

  // /// Set test scaffold messenger state for testing purposes
  // static void setTestScaffoldMessengerState(ScaffoldMessengerState? scaffoldMessengerState) {
  //   _testScaffoldMessengerState = scaffoldMessengerState;
  // }

  /// Clear test scaffold messenger state
  static void clearTestScaffoldMessengerState() {
    _testScaffoldMessengerState = null;
  }

  /// Enable testing mode - skip showing snackbars (useful for integration tests)
  static void enableTestingMode() {
    _testingMode = true;
  }

  /// Disable testing mode - show snackbars normally
  static void disableTestingMode() {
    _testingMode = false;
  }

  /// Display a snackbar with custom styling and behavior
  static void display({
    required String title,
    required String message,
    bool autoDismiss = true,
    Color? backgroundColor,
    int duration = _defaultDurationSeconds,
    SnackBarAction? action,
  }) {
    // Skip showing snackbars in testing mode
    if (_testingMode) {
      return;
    }

    final Color bgColor = backgroundColor ?? Colors.black;
    final Color textColor = contrastColor(bgColor);

    final SnackBar snackBar = SnackBar(
      key: const Key('key_snackbar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: _titleFontSize,
            ),
          ),
          const SizedBox(height: _contentSpacing),
          SelectableText(
            message,
            style: TextStyle(color: textColor, fontSize: _messageFontSize),
          ),
        ],
      ),
      backgroundColor: bgColor,
      duration: autoDismiss ? Duration(seconds: duration) : const Duration(days: _persistDurationDays),
      action:
          action ??
          SnackBarAction(
            key: const Key('key_snackbar_close_button'),
            label: AppL10n.tr(AppTranslationKeys.close),
            textColor: textColor,
            onPressed: () {
              // Dismiss current snackbar
              final ScaffoldMessengerState? state = scaffoldKey.currentState ?? _testScaffoldMessengerState;
              if (state != null) {
                state.hideCurrentSnackBar();
              }
            },
          ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(_snackBarMargin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_snackBarBorderRadius),
      ),
      elevation: _snackBarElevation,
      dismissDirection: DismissDirection.horizontal,
    );

    _showSnackBar(snackBar);
  }

  /// Internal method to show snackbar, handling queue and test mode
  static void _showSnackBar(SnackBar snackBar) {
    // Use test scaffold messenger if available, otherwise use the app's
    final ScaffoldMessengerState? state = _testScaffoldMessengerState ?? scaffoldKey.currentState;

    if (state == null) {
      // Queue the snackbar if no scaffold messenger is available
      _queue.add(_QueuedSnackBar(snackBar));
      _scheduleQueueFlush();
      return;
    }

    try {
      // Show immediately if available
      state.showSnackBar(snackBar);
    } on AssertionError catch (_) {
      // Happens during app startup when no Scaffold descendants exist yet.
      _queue.add(_QueuedSnackBar(snackBar));
      _scheduleQueueFlush();
      return;
    }

    // Process queue after current snackbar
    if (_queue.isNotEmpty) {
      Future<void>.delayed(snackBar.duration, () {
        if (_queue.isNotEmpty) {
          final _QueuedSnackBar next = _queue.removeAt(0);
          _showSnackBar(next.snackBar);
        }
      });
    }
  }

  /// Schedules a post-frame retry to flush the queued snackbars when a messenger becomes available.
  static void _scheduleQueueFlush() {
    if (_flushScheduled || _queue.isEmpty) {
      return;
    }

    _flushScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: _retryDelayMs), () {
        _flushScheduled = false;
        if (_queue.isEmpty) {
          return;
        }
        final _QueuedSnackBar next = _queue.removeAt(0);
        _showSnackBar(next.snackBar);
      });
    });
  }

  /// Display error snackbar
  static void displayError({
    required String message,
    String? title,
    bool autoDismiss = true,
  }) {
    display(
      title: title ?? AppL10n.tr(AppTranslationKeys.error),
      message: message,
      autoDismiss: autoDismiss,
      backgroundColor: Theme.of(AppRouter.context!).extension<MoneyThemeData>()!.getColorForState(ColorState.error),
    );
  }

  /// Display success snackbar
  static void displaySuccess({
    required String message,
    String? title,
    bool autoDismiss = true,
  }) {
    display(
      title: title ?? AppL10n.tr(AppTranslationKeys.success),
      message: message,
      autoDismiss: autoDismiss,
      backgroundColor: Theme.of(AppRouter.context!).extension<MoneyThemeData>()!.getColorForState(ColorState.success),
    );
  }

  /// Display warning snackbar
  static void displayWarning({
    required String message,
    String? title,
    bool autoDismiss = true,
  }) {
    display(
      title: title ?? AppL10n.tr(AppTranslationKeys.warning),
      message: message,
      autoDismiss: autoDismiss,
      backgroundColor: Theme.of(AppRouter.context!).extension<MoneyThemeData>()!.getColorForState(ColorState.warning),
    );
  }

  /// Display info snackbar
  static void displayInfo({
    required String message,
    String? title,
    bool autoDismiss = true,
  }) {
    display(
      title: title ?? AppL10n.tr(AppTranslationKeys.info),
      message: message,
      autoDismiss: autoDismiss,
      backgroundColor: Theme.of(AppRouter.context!).extension<MoneyThemeData>()!.getColorForState(ColorState.info),
    );
  }

  /// Hide current snackbar
  static void hideCurrent() {
    final ScaffoldMessengerState? state = scaffoldKey.currentState ?? _testScaffoldMessengerState;
    state?.hideCurrentSnackBar();
  }

  /// Clear all queued snackbars
  static void clearQueue() {
    _queue.clear();
    _flushScheduled = false;
  }

  /// Get current queue length (useful for testing)
  static int get queueLength => _queue.length;
}

/// Internal class for queuing snackbars
class _QueuedSnackBar {
  const _QueuedSnackBar(this.snackBar);
  final SnackBar snackBar;
}
