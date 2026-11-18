import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_shared_dialog.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widgets_helper.dart';
import 'package:money/widgets/dialogs/confirmation_dialog.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/widgets_domain/data_object_widgets_helper.dart';

/// Builds action buttons for the transaction mutation dialog.
///
/// Arguments:
/// - `context`: Build context of the active dialog.
/// - `transaction`: Current transaction being displayed/edited.
/// - `editMode`: Whether the dialog is currently in edit mode.
/// - `dataWasModified`: Whether transaction data changed in the dialog.
typedef MutationActionButtonsBuilder = List<Widget> Function({
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
  required BuildContext context,
  required Transaction transaction,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext _) {
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
  /// State of the live transaction when Edit was pressed; null once applied or when nothing to undo.
  EditSnapshot? _editSnapshot;

  late Transaction _transaction;

  bool dataWasModified = false;

  bool isInEditingMode = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  @override
  void dispose() {
    final EditSnapshot? snapshot = _editSnapshot;
    if (snapshot != null) {
      // Closed while editing without Apply: roll back once the tree is no longer locked.
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        snapshot.restore();
        Data().updateAll();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    required BuildContext context,
    required Transaction transaction,
    required bool editMode,
    required bool dataWasModified,
  }) {
    if (editMode) {
      return <Widget>[
        DialogActionButton(
          key: Constants.keyButtonApplyOrDone,
          text: dataWasModified ? AppL10n.tr(AppTranslationKeys.apply) : SharedStrings.labelDone,
          onPressed: () {
            _editSnapshot = null;
            // Changes were made
            if (dataWasModified) {
              // Apply a Payee/Transfer change picked in the dialog to the counterpart transaction.
              Data().verifyApplyTransfer(
                transaction: transaction,
                relatedAccount: transaction.editingTransferAccount,
              );
              transaction.editingTransferAccount = null;
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
        text: AppL10n.tr(AppTranslationKeys.close),
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
      // Delete
      DialogActionButton(
        icon: Icons.delete_outlined,
        text: AppL10n.tr(AppTranslationKeys.delete),
        onPressed: () {
          showConfirmationDialog(
            context: context,
            title: SharedStrings.labelDeleteTransaction,
            question: SharedStrings.questionDeleteTransaction,
            content: Column(
              children: buildListOfNamesValuesWidgets(
                transaction,
                builders: entityWidgetBuilders,
                compact: true,
              ),
            ),
            buttonText: AppL10n.tr(AppTranslationKeys.delete),
            onConfirmation: () {
              Data().deleteItems(<DataObject>[transaction]);
              Navigator.of(context).pop(false);
            },
          );
        },
      ),
      // Duplicate
      DialogActionButton(
        icon: Icons.copy_outlined,
        text: SharedStrings.labelDuplicate,
        onPressed: () {
          _transaction = transaction.createDuplicate();

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
        text: AppL10n.tr(AppTranslationKeys.edit),
        onPressed: () {
          _editSnapshot = EditSnapshot(transaction);
          transaction.stashValueBeforeEditing();
          setState(() {
            isInEditingMode = true;
          });
        },
      ),
    ];
  }
}
