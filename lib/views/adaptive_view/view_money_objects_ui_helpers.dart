import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/money_object_card.dart';
import 'package:money/widgets/pivot_toggle_row.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/text_title.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field_filter.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';

/// Builds the standardized pivot toggle row layout.
Widget buildStandardPivotToggleRowUi({
  Key? key,
  required List<bool> selectedPivot,
  required List<Widget> pivotChildren,
  required EdgeInsetsGeometry padding,
  required BorderRadius borderRadius,
  required double minHeight,
  required double minWidth,
  required void Function(int) onPressed,
}) {
  return buildPivotToggleRow(
    key: key,
    isSelected: selectedPivot,
    children: pivotChildren,
    padding: padding,
    borderRadius: borderRadius,
    minHeight: minHeight,
    minWidth: minWidth,
    onPressed: onPressed,
  );
}

/// Builds a common side-panel details wrapper around a money object card.
Widget buildStandardSidePanelDetailsWrapUi<T extends DataObject>({
  required T? selectedItem,
  required List<Widget> extraPanels,
  required double spacing,
  required String title,
}) {
  if (selectedItem == null) {
    return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noItemSelected));
  }

  return SingleChildScrollView(
    child: Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runSpacing: spacing,
        spacing: spacing,
        children: <Widget>[
          MoneyObjectCard(
            title: title,
            moneyObject: selectedItem,
          ),
          ...extraPanels,
        ],
      ),
    ),
  );
}

/// Builds the default empty-list center message.
Widget buildCenterMessageForEmptyListUi({
  required Key key,
  required String classNamePlural,
}) {
  return CenterMessage(key: key, message: 'No $classNamePlural');
}

/// Builds the empty-list message that includes active filters and a clear action.
Widget buildCenterMessageForEmptyListDueToFiltersUi({
  required Key key,
  required String classNamePlural,
  required String filterByText,
  required FieldFilters filterByFieldsValue,
  required VoidCallback onClearFilters,
}) {
  final List<String> activeFilterValues = <String>[];
  if (filterByText.isNotEmpty) {
    activeFilterValues.add('"$filterByText"');
  }
  if (filterByFieldsValue.isNotEmpty) {
    activeFilterValues.addAll(
      filterByFieldsValue.list.map((FieldFilter filter) => filter.toString()),
    );
  }

  return Center(
    child: Box(
      key: key,
      padding: SizeForPadding.large,
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextTitle('No $classNamePlural found with the filters:'),
            gapLarge(),
            SelectableText(activeFilterValues.join('\n')),
            gapHuge(),
            Row(
              children: <Widget>[
                const Spacer(),
                IntrinsicWidth(
                  child: OutlinedButton(
                    onPressed: onClearFilters,
                    child: Row(
                      children: <Widget>[
                        Text(AppL10n.tr(AppTranslationKeys.clearFilters)),
                        gapSmall(),
                        const Icon(Icons.filter_alt_off_outlined),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
