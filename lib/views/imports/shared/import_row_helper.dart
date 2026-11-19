import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

/// Skip reason: the row's date could not be read.
const String importSkipReasonInvalidDate = 'invalidDate';

/// Skip reason: the row's amount could not be read.
const String importSkipReasonInvalidAmount = 'invalidAmount';

/// Skip reason: the row has no usable description.
const String importSkipReasonEmptyDescription = 'emptyDescription';

/// Skip reason: the row is shorter than the columns it must provide.
const String importSkipReasonInsufficientColumns = 'insufficientColumns';

/// Skip reason: the file lacks a column the format requires.
const String importSkipReasonMissingRequiredColumns = 'missingRequiredColumns';

/// Skip reason: a column chosen in the column mapper is not in the headers.
const String importSkipReasonMissingMappedColumns = 'missingMappedColumns';

/// Skip reason: the column mapping lacks the date, description or amount column.
const String importSkipReasonMissingRequiredMapping = 'missingRequiredMapping';

const String _noDescriptionPlaceholder = 'no description';

/// Lower-cases [value] and collapses every run of non-alphanumeric characters
/// into one space, for robust placeholder matching.
String normalizeForPlaceholderCheck(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Returns true when [descriptionValue] is empty or a non-informative placeholder such as `No Description`.
bool isDescriptionPlaceholder(String descriptionValue) {
  final String normalized = normalizeForPlaceholderCheck(descriptionValue);
  return normalized.isEmpty || normalized == _noDescriptionPlaceholder;
}

/// Warns the user when [skipped] rows of a [fileType] file could not be read while [imported] rows were.
void showSkippedRowsWarning({
  required String fileType,
  required int imported,
  required int skipped,
}) {
  if (skipped <= 0) {
    return;
  }
  SnackBarService.displayWarning(
    autoDismiss: true,
    message: AppL10n.tr(
      AppTranslationKeys.importRowsParsedAndSkipped,
      params: <String, String>{
        'fileType': fileType,
        'imported': imported.toString(),
        'skipped': skipped.toString(),
      },
    ),
  );
}
