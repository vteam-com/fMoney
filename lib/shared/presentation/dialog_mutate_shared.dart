import 'package:flutter/widgets.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_auto_size.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';

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
            children: moneyObject.buildListOfNamesValuesWidgets(
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
