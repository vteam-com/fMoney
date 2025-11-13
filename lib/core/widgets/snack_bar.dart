import 'package:money/core/helpers/color_helper.dart';

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
    int duration = 5,
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
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            message,
            style: TextStyle(color: textColor, fontSize: 13),
          ),
        ],
      ),
      backgroundColor: bgColor,
      duration: autoDismiss ? Duration(seconds: duration) : const Duration(days: 1),
      action:
          action ??
          SnackBarAction(
            key: const Key('key_snackbar_close_button'),
            label: 'Close',
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
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 6,
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
      return;
    }

    // Show immediately if available
    state.showSnackBar(snackBar);

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

  /// Display error snackbar
  static void displayError({
    required String message,
    String title = 'Error',
    bool autoDismiss = true,
  }) {
    display(
      title: title,
      message: message,
      autoDismiss: autoDismiss,
      backgroundColor: getColorFromState(ColorState.error),
    );
  }

  /// Display success snackbar
  static void displaySuccess({
    required String message,
    String title = 'Success',
    bool autoDismiss = true,
  }) {
    display(
      title: title,
      message: message,
      autoDismiss: autoDismiss,
      backgroundColor: getColorFromState(ColorState.success),
    );
  }

  /// Display warning snackbar
  static void displayWarning({
    required String message,
    String title = 'Warning',
    bool autoDismiss = true,
  }) {
    display(
      title: title,
      message: message,
      autoDismiss: autoDismiss,
      backgroundColor: getColorFromState(ColorState.warning),
    );
  }

  /// Display info snackbar
  static void displayInfo({
    required String message,
    String title = 'Info',
    bool autoDismiss = true,
  }) {
    display(
      title: title,
      message: message,
      autoDismiss: autoDismiss,
      backgroundColor: getColorFromState(ColorState.info),
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
  }

  /// Get current queue length (useful for testing)
  static int get queueLength => _queue.length;
}

/// Internal class for queuing snackbars
class _QueuedSnackBar {
  const _QueuedSnackBar(this.snackBar);
  final SnackBar snackBar;
}
