import 'package:money/helpers/constants.dart';
import 'package:money/views/data.dart';
import 'package:money/views/dialog_mutate_shared.dart';
import 'package:money/views/providers/transaction_split.dart';
import 'package:money/widgets/confirmation_dialog.dart';
import 'package:money/widgets/dialog_button.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

/// Shows dialog for editing transaction split with action buttons.
Future<dynamic> showSplitAndActions({
  required final BuildContext context,
  required final TransactionSplit split,
}) {
  return showDialog(
    context: context,
    builder: (final BuildContext _) {
      return DialogMutateSplit(split: split);
    },
  );
}

/// Dialog content
class DialogMutateSplit extends StatefulWidget {
  const DialogMutateSplit({required this.split, super.key});

  final TransactionSplit split;

  @override
  State<DialogMutateSplit> createState() => _DialogMutateSplitState();
}

class _DialogMutateSplitState extends State<DialogMutateSplit> {
  late TransactionSplit _split;

  bool dataWasModified = false;

  bool isInEditingMode = false;

  @override
  void initState() {
    super.initState();
    _split = widget.split;
  }

  @override
  Widget build(final BuildContext context) {
    return buildMutationDialogBody(
      moneyObject: _split,
      isInEditingMode: isInEditingMode,
      onEdited: (bool wasModified) {
        setState(() {
          dataWasModified = wasModified || DataObject.isDataModified(_split);
        });
      },
      actionButtons: getActionButtons(
        context: context,
        split: _split,
        editMode: isInEditingMode,
        dataWasModified: dataWasModified,
      ),
    );
  }

  /// Builds action buttons for the split dialog.
  List<Widget> getActionButtons({
    required final BuildContext context,
    required final TransactionSplit split,
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
                moneyObject: split,
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
            title: 'Delete Split',
            question: 'Are you sure you want to delete this Split?',
            content: Column(
              children: split.buildListOfNamesValuesWidgets(compact: true),
            ),
            buttonText: 'Delete',
            onConfirmation: () {
              Data().splits.deleteItem(split);
              Navigator.of(context).pop(false);
            },
          );
        },
      ),
      // Edit
      DialogActionButton(
        key: Constants.keyButtonEdit,
        icon: Icons.edit_outlined,
        text: 'Edit',
        onPressed: () {
          split.stashValueBeforeEditing();
          setState(() {
            isInEditingMode = true;
          });
        },
      ),
    ];
  }
}
