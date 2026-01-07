import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';

Widget dialogActionButtons(final List<Widget> actionsButtons) {
  return Wrap(
    alignment: WrapAlignment.end,
    spacing: SizeForPadding.medium,
    runSpacing: SizeForPadding.medium,
    children: actionsButtons,
  );
}

Widget buildMergeButton(final void Function() callback) {
  return IconButton(
    key: Constants.keyMergeButton,
    onPressed: () {
      callback();
    },
    icon: const Icon(Icons.merge_outlined),
    tooltip: 'Merge item(s)',
  );
}

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

Widget buildAddTransactionsButton(final void Function() callback) {
  return IconButton(
    key: Constants.keyButtonAddTransactions,
    onPressed: () {
      callback();
    },
    icon: const Icon(Icons.post_add_outlined),
    tooltip: 'Add a new transactions',
  );
}

Widget buildEditButton(final void Function() callback) {
  return IconButton(
    key: Constants.keyEditSelectedItems,
    onPressed: () {
      callback.call();
    },
    icon: const Icon(Icons.edit_outlined),
    tooltip: 'Edit selected item(s)',
  );
}

Widget buildDeleteButton(final void Function() callback) {
  return IconButton(
    key: Constants.keyDeleteSelectedItems,
    onPressed: () {
      callback.call();
    },
    icon: const Icon(Icons.delete_outline),
    tooltip: 'Delete selected item(s)',
  );
}

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
    tooltip: 'Copy list to clipboard',
  );
}
