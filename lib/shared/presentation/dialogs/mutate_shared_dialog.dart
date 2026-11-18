import 'package:flutter/widgets.dart';
import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widgets_helper.dart';
import 'package:money/widgets/dialogs/auto_size_dialog.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
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

/// Shared content layout for mutation dialogs.
Widget buildMutationDialogBody({
  required DataObject moneyObject,
  required bool isInEditingMode,
  required void Function(bool) onEdited,
  required List<Widget> actionButtons,
  bool wrapInDialogAutoSize = true,
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

  if (!wrapInDialogAutoSize) {
    return body;
  }

  return DialogAutoSize(child: body);
}

/// Builds mutation dialog body and tracks modifications by consulting [DataObject.isDataModified].
Widget buildMutationDialogBodyWithTrackedChanges<T extends DataObject>({
  required BuildContext context,
  required T moneyObject,
  required bool isInEditingMode,
  required bool dataWasModified,
  required ValueChanged<bool> setDataWasModified,
  required List<Widget> Function(BuildContext, T, bool, bool) actionButtonsBuilder,
}) {
  return buildMutationDialogBody(
    moneyObject: moneyObject,
    isInEditingMode: isInEditingMode,
    onEdited: (bool wasModified) {
      setDataWasModified(wasModified || DataObject.isDataModified(moneyObject));
    },
    actionButtons: actionButtonsBuilder(
      context,
      moneyObject,
      isInEditingMode,
      dataWasModified,
    ),
  );
}
