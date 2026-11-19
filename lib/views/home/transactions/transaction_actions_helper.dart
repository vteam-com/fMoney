import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/alias_pattern_suggestion_helper.dart';
import 'package:money/shared/domain/aliases_collection.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_money_object_dialog.dart';
import 'package:money/shared/presentation/entity_widgets/payee_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/transaction_widgets_helper.dart';
import 'package:money/shared/presentation/helpers/transactions_updated_snack_bar_helper.dart';
import 'package:money/views/panels/dialogs/similar_payees_dialog.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

/// An action on the selected transactions, offered in the right-click menu and as a Ctrl/Cmd shortcut.
typedef TransactionAction = ({
  String label,
  LogicalKeyboardKey key,
  bool shift,
  void Function(BuildContext context, List<Transaction> transactions) run,
});

/// macOS shows the Command key as this symbol.
const String _macCommandSymbol = '⌘';

/// macOS shows the Shift key as this symbol.
const String _macShiftSymbol = '⇧';

/// Other platforms prefix shortcuts with this.
const String _controlPrefix = 'Ctrl+';

/// Other platforms show Shift with this.
const String _shiftPrefix = 'Shift+';

/// Nothing, for a shortcut without Shift.
const String _noModifier = '';

/// The actions offered on selected transactions, in menu order.
List<TransactionAction> get transactionActions => <TransactionAction>[
  (label: AppL10n.tr(AppTranslationKeys.edit), key: LogicalKeyboardKey.keyE, shift: false, run: _edit),
  (
    label: AppL10n.tr(AppTranslationKeys.changeCategory),
    key: LogicalKeyboardKey.keyC,
    shift: true,
    run: _changeCategory,
  ),
  (label: AppL10n.tr(AppTranslationKeys.changePayee), key: LogicalKeyboardKey.keyP, shift: true, run: _changePayee),
  (label: AppL10n.tr(AppTranslationKeys.createAlias), key: LogicalKeyboardKey.keyA, shift: true, run: _createAlias),
  (
    label: AppL10n.tr(AppTranslationKeys.findSimilarPayees),
    key: LogicalKeyboardKey.keyF,
    shift: true,
    run: _findSimilarPayees,
  ),
];

/// Keyboard bindings (with Ctrl or Cmd) that run each action on the transactions [getSelection] returns.
Map<ShortcutActivator, VoidCallback> transactionActionShortcuts(
  BuildContext context,
  List<Transaction> Function() getSelection,
) {
  return <ShortcutActivator, VoidCallback>{
    for (final TransactionAction action in transactionActions)
      for (final bool useMeta in <bool>[false, true])
        SingleActivator(action.key, control: !useMeta, meta: useMeta, shift: action.shift): () {
          final List<Transaction> selection = getSelection();
          if (selection.isNotEmpty) {
            action.run(context, selection);
          }
        },
  };
}

/// Opens the actions menu for [transactions] at the right-click [position].
Future<void> showTransactionActionsMenu(BuildContext context, Offset position, List<Transaction> transactions) async {
  if (transactions.isEmpty) {
    return;
  }
  final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final TransactionAction? chosen = await showMenu<TransactionAction>(
    context: context,
    position: RelativeRect.fromRect(position & Size.zero, Offset.zero & overlay.size),
    items: <PopupMenuEntry<TransactionAction>>[
      for (final TransactionAction action in transactionActions)
        PopupMenuItem<TransactionAction>(
          value: action,
          child: Row(
            children: <Widget>[
              Expanded(child: Text(action.label)),
              gapLarge(),
              Text(_shortcutLabel(action)),
            ],
          ),
        ),
    ],
  );
  if (chosen != null && context.mounted) {
    chosen.run(context, transactions);
  }
}

/// Returns how [action]'s shortcut reads on this platform, such as "Ctrl+Shift+C" or "⇧⌘C".
String _shortcutLabel(TransactionAction action) {
  final bool isApple = defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
  if (isApple) {
    return '${action.shift ? _macShiftSymbol : _noModifier}$_macCommandSymbol${action.key.keyLabel}';
  }
  return '$_controlPrefix${action.shift ? _shiftPrefix : _noModifier}${action.key.keyLabel}';
}

/// Opens the edit dialog on [transactions].
void _edit(BuildContext _, List<Transaction> transactions) {
  myShowDialogAndActionsForMoneyObjects(title: AppL10n.tr(AppTranslationKeys.edit), moneyObjects: transactions);
}

/// Applies [change] to each of [transactions] as a pending edit, then refreshes the data.
void _mutateAll(Iterable<Transaction> transactions, void Function(Transaction transaction) change) {
  for (final Transaction transaction in transactions) {
    transaction.stashValueBeforeEditing();
    change(transaction);
    Data().notifyMutationChanged(mutation: MutationType.changed, moneyObject: transaction, recalculateBalances: false);
  }
  Data().updateAll();
}

/// Asks for a category, suggesting the ones the first transaction's payee uses, and gives it to all [transactions].
void _changeCategory(BuildContext context, List<Transaction> transactions) {
  String chosenName = '';
  adaptiveScreenSizeDialog(
    context: context,
    title: AppL10n.tr(AppTranslationKeys.changeCategory),
    child: StatefulBuilder(
      builder: (BuildContext _, StateSetter setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          pickerCategory(
            key: const Key('key_pick_category'),
            categoryNames: Data().getCategoriesAsStrings(),
            selectedName: chosenName,
            onSelected: (String? name) => chosenName = name ?? '',
          ),
          gapLarge(),
          categorySuggestions(
            categoryNames: suggestedCategoryNamesForPayee(transactions.first.fieldPayee.value),
            onSelected: (String name) => setState(() => chosenName = name),
          ),
        ],
      ),
    ),
    actionButtons: <Widget>[
      DialogActionButton(
        text: AppL10n.tr(AppTranslationKeys.apply),
        onPressed: () {
          final int? categoryId = Data().getCategoryIdFromName(chosenName);
          if (categoryId != null) {
            _mutateAll(transactions, (Transaction t) => t.fieldCategoryId.value = categoryId);
          }
          Navigator.pop(context);
        },
      ),
    ],
  );
}

/// Asks for a payee (existing or new) and gives it to every non-transfer transaction in [transactions].
void _changePayee(BuildContext context, List<Transaction> transactions) {
  int? payeeId;
  adaptiveScreenSizeDialog(
    context: context,
    title: AppL10n.tr(AppTranslationKeys.changePayee),
    child: pickerPayee(
      key: const Key('key_pick_payee'),
      data: Data(),
      onSelected: (DataObject? payee) => payeeId = payee?.uniqueId,
    ),
    actionButtons: <Widget>[
      DialogActionButton(
        text: AppL10n.tr(AppTranslationKeys.apply),
        onPressed: () {
          final int? newPayeeId = payeeId;
          if (newPayeeId != null) {
            _mutateAll(transactions.where((Transaction t) => !t.isTransfer), (Transaction t) {
              t.stashOriginalPayee();
              t.fieldPayee.value = newPayeeId;
              t.applyCategoryFromPayeeHistory();
            });
          }
          Navigator.pop(context);
        },
      ),
    ],
  );
}

/// Opens a new alias for the first transaction's payee that matches the bank text of every one of
/// [transactions] (a regex when they differ); Apply re-assigns every matching transaction, Cancel
/// discards the alias. Transfers, which aliases leave alone, and transactions without any text are
/// skipped; when none is left there is nothing to alias.
void _createAlias(BuildContext _, List<Transaction> transactions) {
  final List<Transaction> aliasable = transactions
      .where((Transaction t) => !t.isTransfer && Aliases.textOf(t).trim().isNotEmpty)
      .toList();
  if (aliasable.isEmpty) {
    return;
  }
  final int payeeId = aliasable.first.fieldPayee.value;
  final Set<String> texts = aliasable.map(Aliases.textOf).toSet();
  final Set<Transaction> selected = aliasable.toSet();
  // One text keeps its plain form; several get one regex, which must leave the other payees' transactions alone
  final Alias alias = Data().aliases.addNewAlias(
    pattern: texts.length == 1
        ? texts.first
        : Data().aliasPatternFor(
            texts,
            (Transaction t) => t.fieldPayee.value == payeeId || selected.contains(t),
          ),
    type: texts.length == 1 ? AliasType.none : AliasType.regex,
    payeeId: payeeId,
  );
  myShowDialogAndActionsForMoneyObject(
    title: AppL10n.tr(AppTranslationKeys.createAlias),
    moneyObject: alias,
    onApplyChange: () {
      final int count = Data().applyAlias(alias);
      Data().updateAll();
      displayTransactionsUpdated(count);
    },
    onCancel: () => Data().deleteItems(<DataObject>[alias]),
    isNew: true,
  );
}

/// Lists the payees similar to the first transaction's payee.
void _findSimilarPayees(BuildContext context, List<Transaction> transactions) {
  final Payee? payee = Data().payees.get(transactions.first.fieldPayee.value);
  if (payee != null) {
    showSimilarPayees(context, payee);
  }
}
