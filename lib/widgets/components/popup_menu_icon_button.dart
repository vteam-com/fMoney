import 'package:money/helpers/color_helper.dart';

const double _popupMenuBorderWidth = 2;
const double _popupMenuBorderRadius = 8;

/// Creates a PopupMenuButton with themed styling and icon.
PopupMenuButton<int> myPopupMenuIconButton({
  Key? key,
  required BuildContext context,
  required IconData icon,
  required String tooltip,
  required List<PopupMenuItem<int>> list,
  required void Function(int) onSelected,
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
    itemBuilder: (BuildContext _) {
      return list;
    },
    onSelected: onSelected,
  );
}
