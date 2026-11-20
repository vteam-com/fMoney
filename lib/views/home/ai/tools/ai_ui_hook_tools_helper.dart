// ignore: fcheck_hardcoded_strings
// Tool names, descriptions and results are written for the AI model, in English; the user never sees them.
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/ai_chat_action_model.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/views/home/ai/tools/ai_tool_args_helper.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';
import 'package:money/views/home/ai/tools/ai_transaction_query_model.dart';

/// Argument: button text.
const String _argLabel = 'label';

/// Argument: which view to open.
const String _argView = 'view';

/// Argument: id of the row to select.
const String _argSelectId = 'select_id';

/// Year before any transaction, starting a date range the model left open.
const int _earliestYear = 1900;

/// Year after any transaction, ending a date range the model left open.
const int _latestYear = 2100;

/// Start of a date range left open by the model.
final DateTime _earliestDate = DateTime(_earliestYear);

/// End of a date range left open by the model.
final DateTime _latestDate = DateTime(_latestYear);

/// The views the model may offer to open, by the name it uses.
const Map<String, ViewId> _viewsByName = <String, ViewId>{
  'cashflow': ViewId.viewCashFlow,
  'events': ViewId.viewEvents,
  'accounts': ViewId.viewAccounts,
  'categories': ViewId.viewCategories,
  'payees': ViewId.viewPayees,
  'aliases': ViewId.viewAliases,
  'transactions': ViewId.viewTransactions,
  'transfers': ViewId.viewTransfers,
  'investments': ViewId.viewInvestments,
  'stocks': ViewId.viewStocks,
  'rentals': ViewId.viewRentals,
};

/// What the tools tell the model after adding a button.
const String _buttonAddedNote =
    'A button with this label was added under your answer; the user clicks it to open the view. '
    'Mention it in your answer.';

/// Returns the UI hook tools, which add to [actions] buttons that open a view of the app from the
/// answer. They never navigate on their own: the user decides whether to click.
List<AiTool> aiUiHookTools(List<AiChatAction> actions) => <AiTool>[
  AiTool(
    name: 'show_transactions',
    description:
        'Adds a button under your answer that opens the Transactions view filtered to these accounts, '
        'categories, dates and text, so the user can review or edit the rows there. Prefer it to listing '
        'many rows in your answer.',
    parameters: <String, Map<String, Object>>{
      _argLabel: aiStringParam('Short button text saying what will be shown, e.g. "Condo transfers 2014".'),
      aiArgAccountIds: AiTransactionQuery.parameters[aiArgAccountIds]!,
      aiArgCategory: AiTransactionQuery.parameters[aiArgCategory]!,
      aiArgDateFrom: AiTransactionQuery.parameters[aiArgDateFrom]!,
      aiArgDateTo: AiTransactionQuery.parameters[aiArgDateTo]!,
      aiArgText: aiStringParam('Text the view keeps rows containing, in any column (payee, memo, category...).'),
      _argSelectId: aiIntParam('Transaction id to select in the view.'),
    },
    required: <String>[_argLabel],
    run: (Map<String, dynamic> args) async {
      actions.add(_transactionsAction(args));
      return <String, String>{'status': _buttonAddedNote};
    },
  ),
  AiTool(
    name: 'open_view',
    description:
        'Adds a button under your answer that opens another view of the app, optionally filtered and on a row.',
    parameters: <String, Map<String, Object>>{
      _argLabel: aiStringParam('Short button text saying what will be shown.'),
      _argView: aiStringParam('The view to open.', values: _viewsByName.keys.toList()),
      _argSelectId: aiIntParam('Id of the row to select (account, category, payee... id).'),
      aiArgText: aiStringParam('Text the view keeps rows containing.'),
    },
    required: <String>[_argLabel, _argView],
    run: (Map<String, dynamic> args) async {
      final ViewId? viewId = _viewsByName[args.stringArg(_argView).toLowerCase()];
      if (viewId == null) {
        throw ArgumentError('Unknown view "${args[_argView]}"; use one of ${_viewsByName.keys.join(', ')}.');
      }
      actions.add(
        AiChatAction(
          label: args.stringArg(_argLabel),
          viewId: viewId,
          selectedId: args.intArg(_argSelectId) ?? -1,
          textFilter: args.stringArg(aiArgText),
        ),
      );
      return <String, String>{'status': _buttonAddedNote};
    },
  ),
];

/// Returns the Transactions view action [args] describes, with the account and category names and
/// dates as column filters.
AiChatAction _transactionsAction(Map<String, dynamic> args) {
  final FieldFilters filters = FieldFilters();
  final List<String> accountNames = args
      .intListArg(aiArgAccountIds)
      .map((int id) => Data().accounts.get(id))
      .whereType<Account>()
      .map((Account account) => account.fieldName.value)
      .toList();
  if (accountNames.isNotEmpty) {
    filters.add(FieldFilter(fieldName: columnIdAccount, strings: accountNames));
  }
  final String category = args.stringArg(aiArgCategory).toLowerCase();
  if (category.isNotEmpty) {
    filters.add(
      FieldFilter(
        fieldName: columnIdCategory,
        strings: Data().categories
            .iterableList()
            .map((Category c) => c.name)
            .where((String name) => name.toLowerCase().contains(category))
            .toList(),
      ),
    );
  }
  final DateTime? dateFrom = args.dateArg(aiArgDateFrom);
  final DateTime? dateTo = args.dateArg(aiArgDateTo);
  if (dateFrom != null || dateTo != null) {
    filters.add(
      FieldFilter(
        fieldName: columnIdDate,
        byDateRange: true,
        strings: <String>[dateToString(dateFrom ?? _earliestDate), dateToString(dateTo ?? _latestDate)],
      ),
    );
  }
  return AiChatAction(
    label: args.stringArg(_argLabel),
    viewId: ViewId.viewTransactions,
    selectedId: args.intArg(_argSelectId) ?? -1,
    textFilter: args.stringArg(aiArgText),
    columnFilters: filters,
  );
}
