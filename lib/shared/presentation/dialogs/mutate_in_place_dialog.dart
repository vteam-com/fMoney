import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/dialogs/delete_money_objects_dialog.dart';
import 'package:money/shared/presentation/dialogs/mutate_shared_dialog.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';

/// Shows one live [moneyObject] read-only, with Close, Delete and Edit; Edit changes it in place.
///
/// Closing the dialog while editing, without Apply, rolls the edit back.
class DialogMutateInPlace<T extends DataObject> extends StatefulWidget {
  const DialogMutateInPlace({
    required this.moneyObject,
    required this.nameSingular,
    required this.namePlural,
    this.onApply,
    this.onDuplicate,
    super.key,
  });

  /// The object shown, and edited in place.
  final T moneyObject;

  /// Name of several such objects, used when confirming a deletion.
  final String namePlural;

  /// Name of one such object, used when confirming its deletion.
  final String nameSingular;

  /// Runs on Apply when the object was modified, before the change is announced.
  final void Function(T moneyObject)? onApply;

  /// Adds a Duplicate button that edits the copy this returns, already added to the data.
  final T Function(T moneyObject)? onDuplicate;

  @override
  State<DialogMutateInPlace<T>> createState() => _DialogMutateInPlaceState<T>();
}

class _DialogMutateInPlaceState<T extends DataObject> extends State<DialogMutateInPlace<T>> {
  bool _dataWasModified = false;

  /// State of the live object when Edit was pressed; null once applied or when nothing to undo.
  EditSnapshot? _editSnapshot;

  bool _isInEditingMode = false;

  /// The object shown: the widget's, or its duplicate.
  late T _moneyObject = widget.moneyObject;

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
    return buildMutationDialogBody(
      moneyObject: _moneyObject,
      isInEditingMode: _isInEditingMode,
      onEdited: (bool wasModified) {
        setState(() {
          _dataWasModified = wasModified || DataObject.isDataModified(_moneyObject);
        });
      },
      actionButtons: _isInEditingMode ? _buildEditingButtons() : _buildReadOnlyButtons(),
    );
  }

  /// Builds the Apply (or Done, when nothing changed) button shown while editing.
  List<Widget> _buildEditingButtons() {
    return <Widget>[
      DialogActionButton(
        key: Constants.keyButtonApplyOrDone,
        text: AppL10n.tr(_dataWasModified ? AppTranslationKeys.apply : AppTranslationKeys.done),
        onPressed: () {
          _editSnapshot = null;
          if (_dataWasModified) {
            widget.onApply?.call(_moneyObject);
            Data().notifyMutationChanged(mutation: MutationType.changed, moneyObject: _moneyObject);
          }
          Navigator.of(context).pop(true);
        },
      ),
    ];
  }

  /// Builds the Close, Delete, optional Duplicate and Edit buttons shown before editing.
  List<Widget> _buildReadOnlyButtons() {
    final T Function(T)? onDuplicate = widget.onDuplicate;
    return <Widget>[
      DialogActionButton(
        text: AppL10n.tr(AppTranslationKeys.close),
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
      DialogActionButton(
        icon: Icons.delete_outlined,
        text: AppL10n.tr(AppTranslationKeys.delete),
        onPressed: () {
          confirmAndDeleteMoneyObjects(
            context: context,
            moneyObjects: <DataObject>[_moneyObject],
            nameSingular: widget.nameSingular,
            namePlural: widget.namePlural,
            onDeleted: () => Navigator.of(context).pop(false),
          );
        },
      ),
      if (onDuplicate != null)
        DialogActionButton(
          icon: Icons.copy_outlined,
          text: AppL10n.tr(AppTranslationKeys.duplicate),
          onPressed: () {
            setState(() {
              _moneyObject = onDuplicate(_moneyObject);
              _isInEditingMode = true;
            });
          },
        ),
      DialogActionButton(
        key: Constants.keyButtonEdit,
        icon: Icons.edit_outlined,
        text: AppL10n.tr(AppTranslationKeys.edit),
        onPressed: () {
          _editSnapshot = EditSnapshot(_moneyObject);
          _moneyObject.stashValueBeforeEditing();
          setState(() {
            _isInEditingMode = true;
          });
        },
      ),
    ];
  }
}
