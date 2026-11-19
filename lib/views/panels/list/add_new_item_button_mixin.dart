import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/presentation/dialogs/mutate_money_object_dialog.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';

/// Puts an "add new item" button first in a list view's main header: it creates the item,
/// selects it and opens it for editing.
mixin AddNewItemButtonMixin on ViewForMoneyObjectsState {
  /// Tooltip of the add button.
  String get addNewItemTooltip;

  /// Creates and stores the new item to edit.
  DataObject createNewItem();

  @override
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    if (!forSidePanelTransactions) {
      list.insert(0, buildAddItemButton(_onAddNewItem, addNewItemTooltip));
    }
    return list;
  }

  /// Creates a new item, selects it and opens the edit dialog on it.
  void _onAddNewItem() {
    final DataObject newItem = createNewItem();
    updateListAndSelect(newItem.uniqueId);
    myShowDialogAndActionsForMoneyObject(
      title: AppL10n.tr(
        AppTranslationKeys.newItemLabel,
        params: <String, String>{'item': getClassNameSingular()},
      ),
      moneyObject: newItem,
      onApplyChange: () {
        setState(() {});
        onEditApplied?.call(<DataObject>[newItem]);
      },
    );
  }
}
