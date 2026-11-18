import 'package:money/helpers/misc_helpers.dart';

/// Parses a number typed in a manual import panel, accepting formats such as
/// `1,200`, `1.234,56` or `$-12.50`.
/// Returns [double.nan] when [text] holds no number, so the caller can refuse to record it.
double parseImportNumberInput(String text) => parseAmountFlexible(text) ?? double.nan;
