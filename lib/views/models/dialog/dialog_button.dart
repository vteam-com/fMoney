import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/models/dialog/menu_entry.dart';
import 'package:money/widgets/gaps.dart';

export 'package:flutter/material.dart';

class DialogActionButton extends StatelessWidget {
  const DialogActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final IconData? icon;
  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Widget child = icon == null
        ? Text(text)
        : IntrinsicWidth(
            child: Row(
              children: <Widget>[
                Opacity(opacity: 0.5, child: Icon(icon)),
                gapSmall(),
                Text(text),
              ],
            ),
          );
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}

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

Widget buildMenuButton(
  final BuildContext context,
  final List<MenuEntry> menuItems, {
  IconData icon = Icons.more_horiz,
  String tooltip = 'Switch view',
}) {
  final List<PopupMenuItem<int>> list = <PopupMenuItem<int>>[];
  for (int i = 0; i < menuItems.length; i++) {
    list.add(
      PopupMenuItem<int>(
        value: i,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Icon(menuItems[i].icon),
            gapLarge(),
            Expanded(child: Text(menuItems[i].title)),
          ],
        ),
      ),
    );
  }
  return myPopupMenuIconButton(
    context: context,
    icon: icon,
    tooltip: tooltip,
    list: list,
    onSelected: (final int index) {
      menuItems[index].onPressed();
    },
  );
}

Widget buildJumpToButton(
  final BuildContext context,
  final List<MenuEntry> listOfViewToJumpTo,
) {
  return buildMenuButton(
    context,
    listOfViewToJumpTo,
    icon: Icons.open_in_new_outlined,
    tooltip: 'Switch view',
  );
}

PopupMenuButton<int> myPopupMenuIconButton({
  final Key? key,
  required final BuildContext context,
  required final IconData icon,
  required final String tooltip,
  required final List<PopupMenuItem<int>> list,
  required final void Function(int) onSelected,
}) {
  return PopupMenuButton<int>(
    key: key,
    icon: Icon(icon),
    tooltip: tooltip,
    position: PopupMenuPosition.under,
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ), // Set the border color and width
      borderRadius: BorderRadius.circular(8), // Set the border radius
    ),
    itemBuilder: (final BuildContext context) {
      return list;
    },
    onSelected: onSelected,
  );
}
