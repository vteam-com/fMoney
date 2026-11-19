import 'package:flutter/widgets.dart';
import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widgets_helper.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/widgets_domain/data_object_widgets_helper.dart';

/// The state of a live object when an edit dialog opened, so an abandoned edit can be rolled back.
///
/// Must be taken before the dialog stashes the object's values.
class EditSnapshot {
  /// Captures [moneyObject]'s persisted values, stash and mutation state.
  EditSnapshot(this.moneyObject)
    : _json = moneyObject.getPersistableJSon(),
      _stashBeforeEdit = moneyObject.valueBeforeEdit,
      _mutationBeforeEdit = moneyObject.mutation,
      _transactionValues = moneyObject is Transaction ? moneyObject.snapshotEditableValues() : null;

  /// The live object being edited.
  final DataObject moneyObject;

  /// Persisted values when the dialog opened.
  final MyJson _json;

  /// The stash that existed before the dialog stashed the object.
  final MyJson? _stashBeforeEdit;

  /// Mutation state when the dialog opened.
  final MutationType _mutationBeforeEdit;

  /// Exact editable values of a [Transaction], including its transfer cache.
  final Transaction? _transactionValues;

  /// Restores the edited values and, when nothing differs any more, drops the "changed" mark the edit added.
  void restore() {
    final DataObject target = moneyObject;
    if (target is Transaction) {
      target.restoreEditableValuesFrom(_transactionValues!);
    } else {
      final MyJson diff = myJsonDiff(before: _json, after: target.getPersistableJSon());
      for (final String key in diff.keys) {
        getFieldDefinitionByName(target.fieldDefinitions, key)?.setValue?.call(target, _json[key]);
      }
    }
    target.valueBeforeEdit = _stashBeforeEdit;

    final bool isRestored = myJsonDiff(before: _json, after: target.getPersistableJSon()).isEmpty;
    if (isRestored && _mutationBeforeEdit == MutationType.none && target.mutation == MutationType.changed) {
      target.mutation = MutationType.none;
      try {
        DataAccess.trackMutations.increaseNumber(increaseChanged: -1);
      } catch (_) {
        // not initialized in unit tests
      }
    }
  }
}

/// Shared content layout for mutation dialogs: the fields of [moneyObject] above the [actionButtons] row.
///
/// [wrapInDialogFrame] puts it in the app's dialog frame ([MyAlertDialog]).
Widget buildMutationDialogBody({
  required DataObject moneyObject,
  required bool isInEditingMode,
  required void Function(bool) onEdited,
  required List<Widget> actionButtons,
  bool wrapInDialogFrame = true,
}) {
  final Widget body = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildListOfNamesValuesWidgets(
              moneyObject,
              builders: entityWidgetBuilders,
              onEdit: isInEditingMode ? onEdited : null,
            ),
          ),
        ),
      ),
      dialogActionButtons(actionButtons),
    ],
  );

  if (!wrapInDialogFrame) {
    return body;
  }

  return MyAlertDialog(title: '', child: body);
}
