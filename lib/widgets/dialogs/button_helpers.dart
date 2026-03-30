import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';

/// Wraps action buttons in a row with end alignment.
Widget dialogActionButtons(final List<Widget> actionsButtons) {
  return Wrap(
    alignment: WrapAlignment.end,
    spacing: SizeForPadding.medium,
    runSpacing: SizeForPadding.medium,
    children: actionsButtons,
  );
}

/// Builds an IconButton for merging items with a key and tooltip.
Widget buildMergeButton(final void Function() callback) {
  return IconButton(
    key: Constants.keyMergeButton,
    onPressed: () {
      callback();
    },
    icon: const Icon(Icons.merge_outlined),
    tooltip: AppL10n.tr(AppTranslationKeys.mergeItems),
  );
}

/// Builds an IconButton for adding a new item with a key and tooltip.
Widget buildAddItemButton(
  final void Function() callback,
  final String tooltip,
) {
  return IconButton(
    key: Constants.keyAddNewItem,
    onPressed: () {
      callback();
    },
    icon: const Icon(Icons.add_circle_outline),
    tooltip: tooltip,
  );
}

/// Builds an IconButton for adding new transactions with a key and tooltip.
Widget buildAddTransactionsButton(final void Function() callback) {
  return IconButton(
    key: Constants.keyButtonAddTransactions,
    onPressed: () {
      callback();
    },
    icon: const Icon(Icons.post_add_outlined),
    tooltip: AppL10n.tr(AppTranslationKeys.addNewTransactions),
  );
}

/// Builds an IconButton for editing selected items with a key and tooltip.
Widget buildEditButton(final void Function() callback) {
  return IconButton(
    key: Constants.keyEditSelectedItems,
    onPressed: () {
      callback.call();
    },
    icon: const Icon(Icons.edit_outlined),
    tooltip: AppL10n.tr(AppTranslationKeys.editSelectedItems),
  );
}

/// Builds an IconButton for deleting selected items with a key and tooltip.
Widget buildDeleteButton(final void Function() callback) {
  return IconButton(
    key: Constants.keyDeleteSelectedItems,
    onPressed: () {
      callback.call();
    },
    icon: const Icon(Icons.delete_outline),
    tooltip: AppL10n.tr(AppTranslationKeys.deleteSelectedItems),
  );
}

/// Builds an IconButton for copying selected items to clipboard with a key.
Widget buildCopyButton(
  final void Function() callback, [
  final Key key = Constants.keyCopyListToClipboardHeaderMain,
]) {
  return IconButton(
    key: key,
    onPressed: () {
      callback.call();
    },
    icon: const Icon(Icons.copy_all),
    tooltip: AppL10n.tr(AppTranslationKeys.copyListToClipboard),
  );
}
