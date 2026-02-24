import 'package:money/helpers/constants.dart';
import 'package:money/providers/transaction.dart';
import 'package:money/views/data.dart';
import 'package:money/views/dialog_mutate_shared.dart';
import 'package:money/widgets/confirmation_dialog.dart';
import 'package:money/widgets/dialog_button.dart';
import 'package:money/widgets/pure/mutation_types.dart';

/// Builds action buttons for the transaction mutation dialog.
///
/// Arguments:
/// - `context`: Build context of the active dialog.
/// - `transaction`: Current transaction being displayed/edited.
/// - `editMode`: Whether the dialog is currently in edit mode.
/// - `dataWasModified`: Whether transaction data changed in the dialog.
typedef MutationActionButtonsBuilder =
    List<Widget> Function({
      required BuildContext context,
      required Transaction transaction,
      required bool editMode,
      required bool dataWasModified,
    });

/// Shows a dialog that allows the user to mutate a transaction.
///
/// The dialog displays the transaction details and provides options to edit or confirm the transaction.
///
/// Parameters:
/// - `context`: The build context used to display the dialog.
/// - `transaction`: The transaction to be displayed and mutated in the dialog.
///
/// Returns:
/// A `Future` that completes when the dialog is closed, with the result of the user's actions.
Future<dynamic> showTransactionAndActions({
  required final BuildContext context,
  required final Transaction transaction,
}) {
  return showDialog(
    context: context,
    builder: (final BuildContext _) {
      return DialogMutateTransaction(transaction: transaction);
    },
  );
}

/// Builds the transaction dialog body while tracking whether its data was edited.
Widget buildTrackedTransactionDialogBody({
  required BuildContext context,
  required Transaction transaction,
  required bool isInEditingMode,
  required bool dataWasModified,
  required ValueChanged<bool> setDataWasModified,
  required MutationActionButtonsBuilder getActionButtons,
}) {
  return buildMutationDialogBodyWithTrackedChanges<Transaction>(
    context: context,
    moneyObject: transaction,
    isInEditingMode: isInEditingMode,
    dataWasModified: dataWasModified,
    setDataWasModified: setDataWasModified,
    actionButtonsBuilder:
        (
          BuildContext context,
          Transaction transaction,
          bool editMode,
          bool dataWasModified,
        ) {
          return getActionButtons(
            context: context,
            transaction: transaction,
            editMode: editMode,
            dataWasModified: dataWasModified,
          );
        },
  );
}

/// Dialog content
/// A stateful widget that represents a dialog for mutating a transaction.
///
/// This widget is responsible for displaying the transaction details and providing options to edit or confirm the transaction.
///
/// The [transaction] parameter is required and represents the transaction to be displayed and mutated in the dialog.
class DialogMutateTransaction extends StatefulWidget {
  const DialogMutateTransaction({required this.transaction, super.key});

  final Transaction transaction;

  @override
  State<DialogMutateTransaction> createState() => _DialogMutateTransactionState();
}

class _DialogMutateTransactionState extends State<DialogMutateTransaction> {
  late Transaction _transaction;

  bool dataWasModified = false;

  bool isInEditingMode = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  @override
  Widget build(final BuildContext context) {
    return buildTrackedTransactionDialogBody(
      context: context,
      transaction: _transaction,
      isInEditingMode: isInEditingMode,
      dataWasModified: dataWasModified,
      setDataWasModified: (bool value) {
        setState(() {
          dataWasModified = value;
        });
      },
      getActionButtons: getActionButtons,
    );
  }

  /// Builds action buttons for the transaction dialog.
  List<Widget> getActionButtons({
    required final BuildContext context,
    required final Transaction transaction,
    required final bool editMode,
    required final bool dataWasModified,
  }) {
    if (editMode) {
      return <Widget>[
        DialogActionButton(
          key: Constants.keyButtonApplyOrDone,
          text: dataWasModified ? 'Apply' : 'Done',
          onPressed: () {
            // Changes were made
            if (dataWasModified) {
              Data().notifyMutationChanged(
                mutation: MutationType.changed,
                moneyObject: transaction,
              );
            }
            Navigator.of(context).pop(true);
          },
        ),
      ];
    }

    // Read only mode
    return <Widget>[
      // Close
      DialogActionButton(
        text: 'Close',
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
      // Delete
      DialogActionButton(
        icon: Icons.delete_outlined,
        text: 'Delete',
        onPressed: () {
          showConfirmationDialog(
            context: context,
            title: 'Delete Transaction',
            question: 'Are you sure you want to delete this transaction?',
            content: Column(
              children: transaction.buildListOfNamesValuesWidgets(
                compact: true,
              ),
            ),
            buttonText: 'Delete',
            onConfirmation: () {
              Data().transactions.deleteItem(transaction);
              Navigator.of(context).pop(false);
            },
          );
        },
      ),
      // Duplicate
      DialogActionButton(
        icon: Icons.copy_outlined,
        text: 'Duplicate',
        onPressed: () {
          _transaction = Transaction(date: transaction.fieldDateTime.value)
            ..fieldId.value = -1
            ..fieldAccountId.value = transaction.fieldAccountId.value
            ..fieldPayee.value = transaction.fieldPayee.value
            ..fieldCategoryId.value = transaction.fieldCategoryId.value
            ..fieldTransfer = transaction.fieldTransfer
            ..fieldAmount.value = transaction.fieldAmount.value
            ..fieldMemo.value = transaction.fieldMemo.value;

          setState(() {
            // append to the list of transactions
            Data().transactions.appendNewMoneyObject(_transaction);
            isInEditingMode = true;
          });
        },
      ),
      // Edit
      DialogActionButton(
        key: Constants.keyButtonEdit,
        icon: Icons.edit_outlined,
        text: 'Edit',
        onPressed: () {
          transaction.stashValueBeforeEditing();
          setState(() {
            isInEditingMode = true;
          });
        },
      ),
    ];
  }
}
