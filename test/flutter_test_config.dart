import 'dart:async';

import 'package:logger/logger.dart';
import 'package:money/helpers/misc_helpers.dart';

/// Silences all log output during tests.
class _SilentFilter extends LogFilter {
  @override
  bool shouldLog(final LogEvent event) => false;
}

/// Configures the test environment before any test suite runs.
///
/// Replaces the global [logger] with a silent instance so that expected
/// warning/debug log calls inside production code do not pollute test output.
/// Real issues still surface through exceptions and test assertions.
Future<void> testExecutable(final FutureOr<void> Function() testMain) async {
  logger = Logger(filter: _SilentFilter());
  await testMain();
}
