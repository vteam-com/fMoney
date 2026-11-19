import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_in_place_dialog.dart';

/// Shows dialog for editing transaction split with action buttons.
Future<dynamic> showSplitAndActions({
  required BuildContext context,
  required TransactionSplit split,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext _) {
      return DialogMutateInPlace<TransactionSplit>(
        moneyObject: split,
        nameSingular: AppL10n.tr(AppTranslationKeys.split),
        namePlural: AppL10n.tr(AppTranslationKeys.splits),
      );
    },
  );
}
