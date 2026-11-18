import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

/// Tells the user that [count] transactions changed.
void displayTransactionsUpdated(int count) {
  SnackBarService.displayInfo(
    message: AppL10n.tr(AppTranslationKeys.transactionsUpdatedCount, params: <String, String>{'count': '$count'}),
  );
}
