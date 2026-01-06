import 'package:money/helpers/color_helper.dart';

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
