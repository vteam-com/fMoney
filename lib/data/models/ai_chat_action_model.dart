import 'package:money/data/models/field_filters_model.dart';
import 'package:money/helpers/constants_helper.dart';

/// JSON key of [AiChatAction.label].
const String _keyLabel = 'label';

/// JSON key of [AiChatAction.viewId], stored by name.
const String _keyView = 'view';

/// JSON key of [AiChatAction.selectedId].
const String _keySelectedId = 'selectedId';

/// JSON key of [AiChatAction.textFilter].
const String _keyTextFilter = 'textFilter';

/// JSON key of [AiChatAction.columnFilters].
const String _keyColumnFilters = 'columnFilters';

/// Id meaning "select nothing" in the destination view.
const int _noSelection = -1;

/// A view the AI offers to open, shown as a button under its answer: the user decides whether to go.
class AiChatAction {
  /// Creates an action that opens [viewId] filtered by [textFilter] and [columnFilters], selecting [selectedId].
  AiChatAction({
    required this.label,
    required this.viewId,
    this.selectedId = _noSelection,
    this.textFilter = '',
    FieldFilters? columnFilters,
  }) : columnFilters = columnFilters ?? FieldFilters();

  /// Restores an action saved by [toJson]; an unknown view name falls back to the Transactions view.
  factory AiChatAction.fromJson(Map<String, dynamic> json) {
    final String viewName = json[_keyView] as String? ?? '';
    return AiChatAction(
      label: json[_keyLabel] as String? ?? '',
      viewId: ViewId.values.firstWhere(
        (ViewId view) => view.name == viewName,
        orElse: () => ViewId.viewTransactions,
      ),
      selectedId: json[_keySelectedId] as int? ?? _noSelection,
      textFilter: json[_keyTextFilter] as String? ?? '',
      columnFilters: FieldFilters.fromJson(
        json[_keyColumnFilters] as Map<String, dynamic>? ?? FieldFilters().toJson(),
      ),
    );
  }

  /// Column filters applied in the destination view.
  final FieldFilters columnFilters;

  /// Button text, written by the AI, saying what the view will show.
  final String label;

  /// Id of the row to select in the destination view, or -1 for none.
  final int selectedId;

  /// Text filter applied in the destination view.
  final String textFilter;

  /// The view to open.
  final ViewId viewId;

  /// Serializes this action for the saved chat history.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      _keyLabel: label,
      _keyView: viewId.name,
      _keySelectedId: selectedId,
      _keyTextFilter: textFilter,
      _keyColumnFilters: columnFilters.toJson(),
    };
  }
}
