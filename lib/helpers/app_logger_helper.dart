import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';

/// Provides structured logging helpers shared across services.
abstract class AppLogger {
  /// Prevents instantiation of the logger helper.
  AppLogger._();

  /// Logs a debug message with required module and operation context.
  static void debug({
    required String module,
    required String operation,
    required String message,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _logWithLevel(
      logCall: logger.d,
      level: SharedStrings.logLevelDebug,
      module: module,
      operation: operation,
      message: message,
      context: context,
    );
  }

  /// Logs an error with required module and operation context.
  static void error({
    required String module,
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    logger.e(
      _buildMessage(
        level: SharedStrings.logLevelError,
        module: module,
        operation: operation,
        context: context,
      ),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a warning with required module and operation context.
  static void warning({
    required String module,
    required String operation,
    required String message,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _logWithLevel(
      logCall: logger.w,
      level: SharedStrings.logLevelWarn,
      module: module,
      operation: operation,
      message: message,
      context: context,
    );
  }

  /// Shared implementation for debug/warning-style log methods.
  static void _logWithLevel({
    required void Function(dynamic message) logCall,
    required String level,
    required String module,
    required String operation,
    required String message,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    logCall(
      _buildMessage(
        level: level,
        module: module,
        operation: operation,
        message: message,
        context: context,
      ),
    );
  }

  /// Builds a normalized, context-rich log message payload.
  static String _buildMessage({
    required String level,
    required String module,
    required String operation,
    String message = '',
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final StringBuffer buffer = StringBuffer()
      ..write('[')
      ..write(level)
      ..write('] ')
      ..write(module)
      ..write('.')
      ..write(operation);
    if (message.isNotEmpty) {
      buffer
        ..write(' - ')
        ..write(message);
    }
    if (context.isNotEmpty) {
      buffer
        ..write(SharedStrings.logContextPrefix)
        ..write(_formatContext(context));
    }
    return buffer.toString();
  }

  /// Converts context map to a deterministic key/value string.
  static String _formatContext(Map<String, Object?> context) {
    final List<String> keys = context.keys.toList()..sort();
    return keys.map((String key) => '$key=${context[key]}').join(', ');
  }
}
