import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/list/multiple_selection_context.dart';

/// Exports
export 'package:money/widgets/list/multiple_selection_context.dart';

/// A stateless widget for multiple selection toggle.
class MultipleSelectionToggle extends StatelessWidget {
  const MultipleSelectionToggle({required this.multipleSelection, super.key});

  final ViewHeaderMultipleSelection? multipleSelection;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = multipleSelection!.isMultiSelectionOn;
    return ValueListenableBuilder<List<int>>(
      valueListenable: multipleSelection!.selectedItems,
      builder:
          (
            final BuildContext context,
            final List<int> _,
            final _,
          ) {
            return Tooltip(
              message: SharedStrings.tooltipToggleMultiSelection,
              child: TextButton.icon(
                key: Constants.keyMultiSelectionToggle,
                icon: const Icon(Icons.checklist),
                label: Text(
                  getIntAsText(multipleSelection!.selectedItems.value.length),
                ),
                onPressed: () {
                  multipleSelection!.onToggleMode!();
                },
                style: TextButton.styleFrom(
                  foregroundColor: isSelected
                      ? getColorTheme(context).onPrimaryContainer
                      : getColorTheme(context).onSecondaryContainer,
                  backgroundColor: isSelected ? getColorTheme(context).primaryContainer : Colors.transparent,
                ),
              ),
            );
          },
    );
  }
}
