import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/adaptive_list/multiple_selection_toggle.dart';
import 'package:money/widgets/filter_input.dart';
import 'package:money/widgets/icon_button.dart';
import 'package:money/widgets/three_part_label.dart';

/// Exports
export 'package:flutter/material.dart';
export 'package:money/widgets/misc_widgets.dart';

/// A widget that displays a header for a view.
///
/// This widget can display a title, description, item count, filter input,
/// clear filters button, and action buttons. It also supports multiple selection
/// and provides callbacks for various actions such as adding, merging, editing,
/// and deleting money objects.
class ViewHeader extends StatelessWidget {
  const ViewHeader({
    super.key,
    required this.title, // The title of the view.
    required this.itemCount, // The number of items in the view.
    required this.selectedItems, // A list of selected item indices.
    required this.description, // A description of the view.
    this.textFilter = '', // The initial text for the filter input.
    this.onTextFilterChanged, // A callback for when the filter text changes.
    this.onClearAllFilters, // A callback for when the clear filters button is pressed.
    this.multipleSelection, // A flag indicating whether multiple selection is enabled.
    this.getActionButtons, // A callback that returns a list of action buttons.
    this.onAddMoneyObject, // A callback for when the add money object button is pressed.
    this.onMergeMoneyObject, // A callback for when the merge money object button is pressed.
    this.onEditMoneyObject, // A callback for when the edit money object button is pressed.
    this.onDeleteMoneyObject, // A callback for when the delete money object button is pressed.
    this.onScrollToTop, // scroll action - top
    this.onScrollToSelection, // scroll action - selection
    this.onScrollToBottom, // scroll action - bottom
    this.child, // An optional child widget to display in the header.
  });

  final Widget? child;

  final String description;

  /// Creates a new instance of [ViewHeader].
  final List<Widget> Function(bool)? getActionButtons;

  final num itemCount;

  final ViewHeaderMultipleSelection? multipleSelection;

  final VoidCallback? onAddMoneyObject;

  final void Function()? onClearAllFilters;

  final VoidCallback? onDeleteMoneyObject;

  final VoidCallback? onEditMoneyObject;

  final VoidCallback? onMergeMoneyObject;

  final VoidCallback? onScrollToBottom;

  final VoidCallback? onScrollToSelection;

  final VoidCallback? onScrollToTop;

  final void Function(String)? onTextFilterChanged;

  final ValueNotifier<List<int>> selectedItems;

  final String textFilter;

  final String title;

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<List<int>>(
      valueListenable: selectedItems,
      builder:
          (
            final BuildContext context,
            final List<int> listOfSelectedItemIndex,
            final _,
            /*widget*/
          ) {
            return buildViewHeaderContainer(context, _buildContent(context));
          },
    );
  }

  /// Builds the container for the view header.
  static Widget buildViewHeaderContainer(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: getColorTheme(context).surfaceContainer),
      child: child,
    );
  }

  Widget _buildContent(final BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    widgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IntrinsicWidth(
            child: Row(
              children: <Widget>[
                ThreePartLabel(
                  text1: title,
                  text2: getIntAsText(itemCount.toInt()),
                ),
                if (onScrollToTop != null)
                  MyIconButton(
                    icon: Icons.first_page,
                    tooltip: 'Scroll to the Top of the list',
                    onPressed: onScrollToTop!,
                  ),
                if (onScrollToSelection != null)
                  MyIconButton(
                    icon: Icons.center_focus_strong,
                    tooltip: 'Scroll to last selection',
                    onPressed: onScrollToSelection!,
                  ),
                if (onScrollToBottom != null)
                  MyIconButton(
                    icon: Icons.last_page,
                    tooltip: 'Scroll to the Bottom of the list',
                    onPressed: onScrollToBottom!,
                  ),
              ],
            ),
          ),
          IntrinsicWidth(
            child: Text(
              description,
              style: getTextTheme(context).bodySmall!.copyWith(
                color: getColorTheme(context).onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );

    if (multipleSelection != null || (getActionButtons != null)) {
      final List<Widget> listOfActionButtons = getActionButtons!(false);

      // Multiple-Selection
      if (multipleSelection != null) {
        listOfActionButtons.insert(
          0,
          MultipleSelectionToggle(multipleSelection: multipleSelection),
        );
      }

      widgets.add(
        IntrinsicWidth(
          child: SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: listOfActionButtons,
            ),
          ),
        ),
      );
    }

    if (child != null) {
      widgets.add(child!);
    }

    if (onTextFilterChanged != null) {
      widgets.add(
        SizedBox(
          width: 200,
          child: FilterInput(
            hintText: 'Filter',
            initialValue: textFilter,
            autoSubmitAfterSeconds: -1, // -1 do not auto submit, user has to press Enter
            onChanged: (final String text) {
              onTextFilterChanged!(text);
            },
          ),
        ),
      );
    }

    if (onClearAllFilters != null) {
      widgets.add(
        IconButton(
          icon: const Icon(Icons.filter_alt_off_outlined),
          tooltip: 'Clear all filters',
          onPressed: onClearAllFilters,
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Wrap(
            spacing: 10.0, // Adjust spacing between child elements
            runSpacing: 10.0,
            alignment: WrapAlignment.spaceBetween,
            children: widgets,
          ),
        ),
      ],
    );
  }
}
