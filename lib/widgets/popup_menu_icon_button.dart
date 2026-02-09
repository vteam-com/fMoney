import 'package:money/helpers/color_helper.dart';

const double _popupMenuBorderWidth = 2;
const double _popupMenuBorderRadius = 8;

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
        width: _popupMenuBorderWidth,
      ), // Set the border color and width
      borderRadius: BorderRadius.circular(
        _popupMenuBorderRadius,
      ), // Set the border radius
    ),
    itemBuilder: (final BuildContext _) {
      return list;
    },
    onSelected: onSelected,
  );
}
