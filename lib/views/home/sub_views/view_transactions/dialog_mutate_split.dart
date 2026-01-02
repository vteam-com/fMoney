import 'package:money/data/data.dart';
import 'package:money/models/money_objects/splits/money_split.dart';
import 'package:money/views/dialog/confirmation_dialog.dart';
import 'package:money/views/dialog/dialog_button.dart';
import 'package:money/views/dialog/dialog_full_screen.dart';

Future<dynamic> showSplitAndActions({
  required final BuildContext context,
  required final MoneySplit split,
}) {
  return showDialog(
    context: context,
    builder: (final BuildContext context) {
      return DialogMutateSplit(split: split);
    },
  );
}

/// Dialog content
class DialogMutateSplit extends StatefulWidget {
  const DialogMutateSplit({required this.split, super.key});

  final MoneySplit split;

  @override
  State<DialogMutateSplit> createState() => _DialogMutateSplitState();
}

class _DialogMutateSplitState extends State<DialogMutateSplit> {
  late MoneySplit _split;

  bool dataWasModified = false;

  bool isInEditingMode = false;

  @override
  void initState() {
    super.initState();
    _split = widget.split;
  }

  @override
  Widget build(final BuildContext context) {
    return AutoSizeDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _split.buildListOfNamesValuesWidgets(
                  onEdit: isInEditingMode
                      ? (bool wasModified) {
                          setState(() {
                            dataWasModified = wasModified || isDataModified();
                          });
                        }
                      : null,
                ),
              ),
            ),
          ),
          dialogActionButtons(
            getActionButtons(
              context: context,
              split: _split,
              editMode: isInEditingMode,
              dataWasModified: dataWasModified,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getActionButtons({
    required final BuildContext context,
    required final MoneySplit split,
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

  bool isDataModified() {
    final MyJson afterEditing = _split.getPersistableJSon();
    final MyJson diff = myJsonDiff(
      before: _split.valueBeforeEdit ?? <String, dynamic>{},
      after: afterEditing,
    );
    return diff.keys.isNotEmpty;
  }
}
