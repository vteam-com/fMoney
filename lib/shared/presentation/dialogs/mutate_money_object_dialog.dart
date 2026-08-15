import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_shared_dialog.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/dialogs/message_box_dialog.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';

/// Shows dialog for editing a single money object with action buttons.
void myShowDialogAndActionsForMoneyObject({
  required String title,
  required DataObject moneyObject,
  void Function()? onApplyChange,
}) {
  myShowDialogAndActionsForMoneyObjects(
    title: title,
    moneyObjects: <DataObject>[moneyObject],
    onApplyChange: onApplyChange,
  );
}

/// Shows dialog for editing multiple money objects with action buttons.
void myShowDialogAndActionsForMoneyObjects({
  required String title,
  required List<DataObject> moneyObjects,
  void Function()? onApplyChange,
}) {
  final BuildContext context = AppRouter.context!;

  if (moneyObjects.isEmpty) {
    messageBox(context, SharedStrings.messageNoItemsToEdit);
    return;
  }

  // Before we edit lets stash the current values of each objects
  for (final DataObject m in moneyObjects) {
    m.stashValueBeforeEditing();
  }

  final DataObject rollup = moneyObjects[0].rollup(moneyObjects);
  final MyJson beforeEditing = rollup.getPersistableJSon();

  return adaptiveScreenSizeDialog(
    context: context,
    title: moneyObjects.length == 1 ? title : '${getIntAsText(moneyObjects.length)} $title',
    captionForClose: null, // this will hide the close button
    child: DialogMutateMoneyObject(
      moneyObject: rollup,
      onApplyChange: (DataObject _) {
        final MyJson afterEditing = rollup.getPersistableJSon();
        final MyJson diff = myJsonDiff(
          before: beforeEditing,
          after: afterEditing,
        );

        if (diff.keys.isNotEmpty) {
          for (final DataObject m in moneyObjects) {
            diff.forEach((String key, dynamic value) {
              // Very Special Edge case for Transaction that are editing the Payee to Transfer
              if (m is Transaction) {
                if (key == 'Payee' || key == 'Transfer') {
                  // Clean or Apply Transfers to all related instances
                  Data().verifyApplyTransfer(
                    transaction: m,
                    relatedAccount: (rollup as Transaction).editingTransferAccount,
                  );
                }
              }
              m.mutateField(key, value['after'], false);
            });
          }
        }
        Data().updateAll();
        onApplyChange?.call();
      },
    ),
  );
}

/// Dialog content
class DialogMutateMoneyObject extends StatefulWidget {
  const DialogMutateMoneyObject({
    super.key,
    required this.moneyObject,
    required this.onApplyChange,
  });

  final DataObject moneyObject;
  final void Function(DataObject) onApplyChange;

  @override
  State<DialogMutateMoneyObject> createState() => _DialogMutateMoneyObjectState();
}

class _DialogMutateMoneyObjectState extends State<DialogMutateMoneyObject> {
  late DataObject _moneyObject;

  bool dataWasModified = false;

  @override
  void initState() {
    super.initState();
    _moneyObject = widget.moneyObject;
  }

  @override
  Widget build(BuildContext context) {
    return buildMutationDialogBody(
      moneyObject: _moneyObject,
      isInEditingMode: true,
      wrapInDialogAutoSize: false,
      onEdited: (bool wasModified) {
        setState(() {
          dataWasModified = wasModified || DataObject.isDataModified(_moneyObject);
        });
      },
      actionButtons: getActionButtons(
        context: context,
        moneyObject: _moneyObject,
        editMode: true,
        dataWasModified: dataWasModified,
      ),
    );
  }

  /// Builds action buttons for the money object dialog.
  List<Widget> getActionButtons({
    required BuildContext context,
    required DataObject moneyObject,
    required bool editMode,
    required bool dataWasModified,
  }) {
    return <Widget>[
      // Cancel
      DialogActionButton(
        text: AppL10n.tr(AppTranslationKeys.cancel),
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),

      // Apply
      if (editMode && dataWasModified)
        DialogActionButton(
          text: AppL10n.tr(AppTranslationKeys.apply),
          onPressed: () {
            // Changes were made
            if (dataWasModified) {
              widget.onApplyChange(moneyObject);
            }
            Navigator.of(context).pop(true);
          },
        ),
    ];
  }
}
