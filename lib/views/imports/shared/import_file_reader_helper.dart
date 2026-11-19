import 'dart:convert';
import 'dart:io';

import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

/// Decodes [bytes] as UTF-8, falling back to Latin-1 for legacy bank files.
String decodeImportFileBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes, allowInvalid: true);
  }
}

/// Reads [filePath] as text with [decodeImportFileBytes].
/// Shows an error and returns null when the file cannot be read.
Future<String?> readImportFileAsText(String filePath) async {
  try {
    return decodeImportFileBytes(await File(filePath).readAsBytes());
  } catch (error) {
    logger.e('Error reading file: $error');
    SnackBarService.displayError(
      autoDismiss: false,
      message: AppL10n.tr(
        AppTranslationKeys.importUnableToReadFile,
        params: <String, String>{'error': error.toString()},
      ),
    );
    return null;
  }
}
