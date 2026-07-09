import 'package:flutter/widgets.dart';
import 'package:money/shared/presentation/helpers/money_objects_ui_helper.dart';
import 'package:money/widgets/pure/working_indicator_widget.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';

/// Builds the empty-state UI for money-object list views.
Widget buildMoneyObjectsEmptyState({
  required final Key key,
  required final String classNamePlural,
  required final bool areFiltersOn,
  required final String filterByText,
  required final FieldFilters filterByFieldsValue,
  required final VoidCallback onClearFilters,
  required final Widget header,
}) {
  return Column(
    children: <Widget>[
      header,
      Expanded(
        child: areFiltersOn
            ? _buildCenterMessageForEmptyListDueToFilters(
                key: key,
                classNamePlural: classNamePlural,
                filterByText: filterByText,
                filterByFieldsValue: filterByFieldsValue,
                onClearFilters: onClearFilters,
              )
            : _buildCenterMessageForEmptyList(
                key: key,
                classNamePlural: classNamePlural,
              ),
      ),
    ],
  );
}

/// Builds the loading-state UI for money-object list views.
Widget buildMoneyObjectsLoadingScreen({
  required final Widget header,
}) {
  return Column(
    children: <Widget>[
      header,
      const Expanded(child: WorkingIndicator()),
    ],
  );
}

/// Builds the generic empty-list center message.
Widget _buildCenterMessageForEmptyList({
  required final Key key,
  required final String classNamePlural,
}) {
  return buildCenterMessageForEmptyListUi(
    key: key,
    classNamePlural: classNamePlural,
  );
}

/// Builds a message explaining that filters resulted in an empty list.
Widget _buildCenterMessageForEmptyListDueToFilters({
  required final Key key,
  required final String classNamePlural,
  required final String filterByText,
  required final FieldFilters filterByFieldsValue,
  required final VoidCallback onClearFilters,
}) {
  return buildCenterMessageForEmptyListDueToFiltersUi(
    key: key,
    classNamePlural: classNamePlural,
    filterByText: filterByText,
    filterByFieldsValue: filterByFieldsValue,
    onClearFilters: onClearFilters,
  );
}
