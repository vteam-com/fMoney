import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';

/// Lays out dialog action buttons in an end-aligned row that stacks them, still end-aligned, when they do not fit.
Widget dialogActionButtons(List<Widget> actionsButtons) {
  return OverflowBar(
    alignment: MainAxisAlignment.end,
    spacing: SizeForPadding.normal,
    overflowAlignment: OverflowBarAlignment.end,
    children: actionsButtons,
  );
}

/// Builds an [IconButton] with a test [key], an [icon] and a [tooltip] that runs [onPressed].
Widget _keyedIconButton({
  required Key key,
  required IconData icon,
  required String tooltip,
  required void Function() onPressed,
}) {
  return IconButton(
    key: key,
    onPressed: onPressed,
    icon: Icon(icon),
    tooltip: tooltip,
  );
}

/// Builds an IconButton that applies the selected alias to existing transactions.
Widget buildApplyAliasButton(void Function() callback) => _keyedIconButton(
  key: Constants.keyApplyAliasButton,
  icon: Icons.published_with_changes,
  tooltip: AppL10n.tr(AppTranslationKeys.applyAliasToTransactions),
  onPressed: callback,
);

/// Builds an IconButton that lists the payees similar to the selected one.
Widget buildFindSimilarPayeesButton(void Function() callback) => _keyedIconButton(
  key: Constants.keyFindSimilarPayeesButton,
  icon: Icons.manage_search,
  tooltip: AppL10n.tr(AppTranslationKeys.findSimilarPayees),
  onPressed: callback,
);

/// Builds an IconButton for merging items with a key and tooltip.
Widget buildMergeButton(void Function() callback) => _keyedIconButton(
  key: Constants.keyMergeButton,
  icon: Icons.merge_outlined,
  tooltip: AppL10n.tr(AppTranslationKeys.mergeItems),
  onPressed: callback,
);

/// Builds an IconButton for adding a new item with a key and tooltip.
Widget buildAddItemButton(
  void Function() callback,
  String tooltip,
) => _keyedIconButton(
  key: Constants.keyAddNewItem,
  icon: Icons.add_circle_outline,
  tooltip: tooltip,
  onPressed: callback,
);

/// Builds an IconButton for adding new transactions with a key and tooltip.
Widget buildAddTransactionsButton(void Function() callback) => _keyedIconButton(
  key: Constants.keyButtonAddTransactions,
  icon: Icons.post_add_outlined,
  tooltip: AppL10n.tr(AppTranslationKeys.addNewTransactions),
  onPressed: callback,
);

/// Builds an IconButton for editing selected items with a key and tooltip.
Widget buildEditButton(void Function() callback) => _keyedIconButton(
  key: Constants.keyEditSelectedItems,
  icon: Icons.edit_outlined,
  tooltip: AppL10n.tr(AppTranslationKeys.editSelectedItems),
  onPressed: callback,
);

/// Builds an IconButton for deleting selected items with a key and tooltip.
Widget buildDeleteButton(void Function() callback) => _keyedIconButton(
  key: Constants.keyDeleteSelectedItems,
  icon: Icons.delete_outline,
  tooltip: AppL10n.tr(AppTranslationKeys.deleteSelectedItems),
  onPressed: callback,
);

/// Builds an IconButton for copying to the clipboard with a [key] and a [tooltip] (by default "Copy list to clipboard").
Widget buildCopyButton(
  void Function() callback, [
  Key key = Constants.keyCopyListToClipboardHeaderMain,
  String? tooltip,
]) => _keyedIconButton(
  key: key,
  icon: Icons.copy_all,
  tooltip: tooltip ?? AppL10n.tr(AppTranslationKeys.copyListToClipboard),
  onPressed: callback,
);
