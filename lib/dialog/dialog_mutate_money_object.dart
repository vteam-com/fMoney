import 'package:get/get.dart';
import 'package:money/dialog/dialog.dart';
import 'package:money/dialog/dialog_button.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/money_objects/transactions/transaction.dart';
import 'package:money/widgets/message_box.dart';
import 'package:money/widgets_data/data/data.dart';
import 'package:money/widgets_data/money_object/money_object.dart';

void myShowDialogAndActionsForMoneyObject({
  required final String title,
  required final MoneyObject moneyObject,
  void Function()? onApplyChange,
}) {
  myShowDialogAndActionsForMoneyObjects(
    title: title,
    moneyObjects: <MoneyObject>[moneyObject],
    onApplyChange: onApplyChange,
  );
}

void myShowDialogAndActionsForMoneyObjects({
  required final String title,
  required final List<MoneyObject> moneyObjects,
  void Function()? onApplyChange,
}) {
  final BuildContext context = Get.context!;

  if (moneyObjects.isEmpty) {
    messageBox(context, 'No items to edit');
    return;
  }

  // Before we edit lets stash the current values of each objects
  for (final MoneyObject m in moneyObjects) {
    m.stashValueBeforeEditing();
  }

  final MoneyObject rollup = moneyObjects[0].rollup(moneyObjects);
  final MyJson beforeEditing = rollup.getPersistableJSon();

  return adaptiveScreenSizeDialog(
    context: context,
    title: moneyObjects.length == 1 ? title : '${getIntAsText(moneyObjects.length)} $title',
    captionForClose: null, // this will hide the close button
    child: DialogMutateMoneyObject(
      moneyObject: rollup,
      onApplyChange: (MoneyObject objectChanged) {
        final MyJson afterEditing = rollup.getPersistableJSon();
        final MyJson diff = myJsonDiff(
          before: beforeEditing,
          after: afterEditing,
        );

        if (diff.keys.isNotEmpty) {
          for (final MoneyObject m in moneyObjects) {
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

  final MoneyObject moneyObject;
  final void Function(MoneyObject) onApplyChange;

  @override
  State<DialogMutateMoneyObject> createState() => _DialogMutateMoneyObjectState();
}

class _DialogMutateMoneyObjectState extends State<DialogMutateMoneyObject> {
  late MoneyObject _moneyObject;

  bool dataWasModified = false;

  @override
  void initState() {
    super.initState();
    _moneyObject = widget.moneyObject;
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _moneyObject.buildListOfNamesValuesWidgets(
                onEdit: (bool wasModified) {
                  setState(() {
                    dataWasModified = wasModified || MoneyObject.isDataModified(_moneyObject);
                  });
                },
              ),
            ),
          ),
        ),
        dialogActionButtons(
          getActionButtons(
            context: context,
            moneyObject: _moneyObject,
            editMode: true,
            dataWasModified: dataWasModified,
          ),
        ),
      ],
    );
  }

  List<Widget> getActionButtons({
    required BuildContext context,
    required MoneyObject moneyObject,
    required bool editMode,
    required bool dataWasModified,
  }) {
    return <Widget>[
      // Cancel
      DialogActionButton(
        text: 'Cancel',
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),

      // Apply
      if (dataWasModified)
        DialogActionButton(
          text: 'Apply',
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
