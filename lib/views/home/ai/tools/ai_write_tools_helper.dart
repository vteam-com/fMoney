// ignore: fcheck_hardcoded_strings
// Tool names, descriptions and results are written for the AI model, in English; the user never sees them.
import 'package:collection/collection.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transfer_linkage_service.dart';
import 'package:money/shared/presentation/dialogs/merge_payees_dialog.dart';
import 'package:money/views/home/ai/tools/ai_data_tools_helper.dart';
import 'package:money/views/home/ai/tools/ai_tool_args_helper.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';
import 'package:money/views/home/ai/tools/ai_transaction_query_model.dart';
import 'package:money/views/home/transactions/transaction_actions_helper.dart';

/// Argument: the transactions to change.
const String _argTransactionIds = 'transaction_ids';

/// Argument: a category full name.
const String _argCategory = 'category';

/// Argument: a category id.
const String _argCategoryId = 'category_id';

/// Argument: one side of a transfer.
const String _argTransactionId = 'transaction_id';

/// Argument: the other side of a transfer.
const String _argOtherTransactionId = 'other_transaction_id';

/// Argument: the payees merged away.
const String _argFromPayeeIds = 'from_payee_ids';

/// Argument: the payee kept.
const String _argToPayeeId = 'to_payee_id';

/// Argument: an alias pattern.
const String _argPattern = 'pattern';

/// Argument: the payee an alias renames to.
const String _argPayeeId = 'payee_id';

/// Argument: the alias pattern is a regular expression.
const String _argIsRegex = 'is_regex';

/// Most transactions one change may touch.
const int _maxTransactionsPerChange = 500;

/// Transactions a transfer link changes: both sides.
const int _transferSides = 2;

/// Most rows listed in the confirmation dialog; its summary gives the full count.
const int _maxDetailLines = 12;

/// Most similar names suggested when a category name is not found.
const int _maxSuggestions = 10;

/// What the tools tell the model when the user declines.
const String _declinedNote = 'The user declined this change. Do not retry it unless asked.';

/// What the tools tell the model after applying.
const String _appliedNote =
    'Applied as pending edits: nothing is saved until the user saves, and the user can still discard it.';

/// Asks the user to apply a change: [summary] says what changes and [details] lists the rows it touches.
/// Completes with true only when the user agrees.
typedef AiConfirmChange = Future<bool> Function({required String summary, required List<String> details});

/// Returns the tools that change data. Each asks [confirm] first and, when the user agrees, makes the
/// change as pending in-memory edits through the same code as the app's menus. None of them saves:
/// saving, or discarding, stays the user's decision.
List<AiTool> aiWriteTools(AiConfirmChange confirm) => <AiTool>[
  AiTool(
    name: 'set_category',
    description:
        'Proposes giving one category to transactions. The user confirms in a dialog; the change stays '
        'pending until the user saves. The category must already exist (see list_categories).',
    parameters: <String, Map<String, Object>>{
      _argTransactionIds: aiIntListParam('Ids of the transactions to change.'),
      _argCategory: aiStringParam('Full category name, e.g. "Housing:Condo Fees".'),
      _argCategoryId: aiIntParam('Category id; used instead of the name when given.'),
    },
    required: <String>[_argTransactionIds],
    run: (Map<String, dynamic> args) => _setCategory(args, confirm),
  ),
  AiTool(
    name: 'link_transfer',
    description:
        'Proposes linking two existing transactions in different accounts, with opposite amounts, as one '
        'transfer (see find_transfer_matches). The user confirms; the change stays pending until saved.',
    parameters: <String, Map<String, Object>>{
      _argTransactionId: aiIntParam('Id of one side.'),
      _argOtherTransactionId: aiIntParam('Id of the other side.'),
    },
    required: <String>[_argTransactionId, _argOtherTransactionId],
    run: (Map<String, dynamic> args) => _linkTransfer(args, confirm),
  ),
  AiTool(
    name: 'merge_payees',
    description:
        'Proposes moving every transaction, split line and alias of some payees to another payee, then '
        'removing the emptied payees. The user confirms; the change stays pending until saved.',
    parameters: <String, Map<String, Object>>{
      _argFromPayeeIds: aiIntListParam('Ids of the payees merged away.'),
      _argToPayeeId: aiIntParam('Id of the payee that remains.'),
    },
    required: <String>[_argFromPayeeIds, _argToPayeeId],
    run: (Map<String, dynamic> args) => _mergePayees(args, confirm),
  ),
  AiTool(
    name: 'create_alias',
    description:
        'Proposes an alias that renames to this payee every transaction whose bank text matches the pattern, '
        'now and in future imports. A plain pattern must equal the whole bank text (ignoring case); a regular '
        'expression must match all of it. The user confirms; the change stays pending until saved.',
    parameters: <String, Map<String, Object>>{
      _argPattern: aiStringParam('Bank text to match, e.g. "AMZN MKTP CA", or a regex like "AMZN MKTP.*".'),
      _argPayeeId: aiIntParam('Id of the payee the matching transactions get.'),
      _argIsRegex: aiBoolParam('true when the pattern is a regular expression.'),
    },
    required: <String>[_argPattern, _argPayeeId],
    run: (Map<String, dynamic> args) => _createAlias(args, confirm),
  ),
];

/// Returns what the tools tell the model after [applied] (or not) a change touching [count] rows.
Map<String, Object> _outcome(bool applied, int count) => applied
    ? <String, Object>{'applied': true, 'changed': count, 'note': _appliedNote}
    : <String, Object>{'applied': false, 'note': _declinedNote};

/// Returns one confirmation-dialog line describing [t].
String _detailLine(Transaction t) =>
    '${dateToString(t.fieldDateTime.value)}   ${t.accountName}   ${t.fieldAmount.value}   ${aiPayeeOrTransferName(t)}';

/// Returns the first [_maxDetailLines] dialog lines for [transactions].
List<String> _detailLines(Iterable<Transaction> transactions) =>
    transactions.take(_maxDetailLines).map(_detailLine).toList();

/// Returns the category [args] names by id or full name, or throws listing similar names.
Category _categoryFromArgs(Map<String, dynamic> args) {
  final int? id = args.intArg(_argCategoryId);
  final Category? byId = id == null ? null : Data().categories.get(id);
  if (byId != null) {
    return byId;
  }
  final String name = args.stringArg(_argCategory);
  final List<Category> similar = name.isEmpty ? <Category>[] : aiCategoriesNamed(name).toList();
  final Category? byName = similar.firstWhereOrNull((Category c) => c.name.toLowerCase() == name.toLowerCase());
  if (byName != null) {
    return byName;
  }
  throw ArgumentError(
    'No category "${args[_argCategory] ?? id}". Similar: '
    '${similar.take(_maxSuggestions).map((Category c) => c.name).join(', ')}. The AI cannot create categories.',
  );
}

/// Returns the live transactions [args] lists under [key], or throws when any id is unknown.
List<Transaction> _transactionsFromArgs(Map<String, dynamic> args, String key) {
  final List<int> ids = args.intListArg(key);
  if (ids.isEmpty || ids.length > _maxTransactionsPerChange) {
    throw ArgumentError('Give between 1 and $_maxTransactionsPerChange transaction ids in $key.');
  }
  return ids.map((int id) => aiItemById(id, Data().transactions, 'search_transactions')).toList();
}

/// Proposes, then makes, the alias [args] describes, and applies it to the matching transactions.
Future<Map<String, Object>> _createAlias(Map<String, dynamic> args, AiConfirmChange confirm) async {
  final String pattern = args.stringArg(_argPattern);
  final Payee payee = aiPayeeFromArgs(args, _argPayeeId);
  final AliasType type = (args.boolArg(_argIsRegex) ?? false) ? AliasType.regex : AliasType.none;
  if (pattern.isEmpty) {
    throw ArgumentError('Give the bank text to match in $_argPattern.');
  }
  if (type == AliasType.regex && tryParseAliasRegex(pattern) == null) {
    throw ArgumentError('Invalid regular expression: $pattern');
  }
  final Alias preview = Alias(id: -1, pattern: pattern, flags: type.index, payeeId: payee.uniqueId, data: Data());
  final List<Transaction> renamed = Data().transactionsRenamedBy(preview).toList();
  final bool applied = await confirm(
    summary: AppL10n.tr(
      AppTranslationKeys.aiChangeCreateAlias,
      params: <String, String>{'pattern': pattern, 'payee': payee.fieldName.value, 'count': '${renamed.length}'},
    ),
    details: _detailLines(renamed),
  );
  if (!applied) {
    return _outcome(false, 0);
  }
  final Alias alias = Data().aliases.addNewAlias(pattern: pattern, type: type, payeeId: payee.uniqueId);
  final int count = Data().applyAlias(alias);
  Data().updateAll();
  return _outcome(true, count);
}

/// Proposes, then makes, the transfer link [args] describes.
Future<Map<String, Object>> _linkTransfer(Map<String, dynamic> args, AiConfirmChange confirm) async {
  final Transaction a = aiTransactionFromArgs(args, _argTransactionId);
  final Transaction b = aiTransactionFromArgs(args, _argOtherTransactionId);
  if (!canLinkAsTransfer(a, b)) {
    throw ArgumentError(
      'Cannot link them: a transfer needs two different transactions, in different accounts, neither already '
      'a transfer, with opposite amounts.',
    );
  }
  final bool applied = await confirm(
    summary: AppL10n.tr(AppTranslationKeys.aiChangeLinkTransfer),
    details: _detailLines(<Transaction>[a, b]),
  );
  if (!applied) {
    return _outcome(false, 0);
  }
  final bool linked = Data().convertDisconnectedTransactionsToTransfer(transaction: a, relatedTransaction: b);
  return _outcome(linked, linked ? _transferSides : 0);
}

/// Proposes, then makes, the payee merge [args] describes.
Future<Map<String, Object>> _mergePayees(Map<String, dynamic> args, AiConfirmChange confirm) async {
  final Payee to = aiPayeeFromArgs(args, _argToPayeeId);
  final List<Payee> from = args
      .intListArg(_argFromPayeeIds)
      .where((int id) => id != to.uniqueId)
      .map((int id) => aiItemById(id, Data().payees, 'list_payees'))
      .toList();
  if (from.isEmpty) {
    throw ArgumentError('Give at least one payee id, other than $_argToPayeeId, in $_argFromPayeeIds.');
  }
  final List<int> fromIds = from.map((Payee p) => p.uniqueId).toList();
  final List<Transaction> moved = Data().transactions
      .iterableList()
      .where((Transaction t) => fromIds.any(t.isForPayee))
      .toList();
  final bool applied = await confirm(
    summary: AppL10n.tr(
      AppTranslationKeys.aiChangeMergePayees,
      params: <String, String>{'payee': to.fieldName.value, 'count': '${moved.length}'},
    ),
    details: from.map((Payee p) => p.fieldName.value).toList(),
  );
  if (!applied) {
    return _outcome(false, 0);
  }
  // Payees with only split lines or aliases merge first; the move below merges those with transactions.
  Data().mergePayeesWithNoTransactionsInto(fromIds, to.uniqueId);
  mutateMergeableItemsToPayee<Transaction>(moved, to.uniqueId, null, Data());
  return _outcome(true, moved.length);
}

/// Proposes, then makes, the category change [args] describes.
Future<Map<String, Object>> _setCategory(Map<String, dynamic> args, AiConfirmChange confirm) async {
  final List<Transaction> transactions = _transactionsFromArgs(args, _argTransactionIds);
  final Category category = _categoryFromArgs(args);
  final bool applied = await confirm(
    summary: AppL10n.tr(
      AppTranslationKeys.aiChangeSetCategory,
      params: <String, String>{'category': category.name, 'count': '${transactions.length}'},
    ),
    details: _detailLines(transactions),
  );
  if (!applied) {
    return _outcome(false, 0);
  }
  mutateTransactions(transactions, (Transaction t) => t.fieldCategoryId.value = category.uniqueId);
  return _outcome(true, transactions.length);
}
