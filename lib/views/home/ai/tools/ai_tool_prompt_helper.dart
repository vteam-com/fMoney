// ignore: fcheck_hardcoded_strings
// Tool names, descriptions and results are written for the AI model, in English; the user never sees them.
import 'package:money/data/models/ai_chat_model.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/account_entity.dart';

/// Chat role of the instructions.
const String _roleSystem = 'system';

/// Chat role of the user's messages.
const String _roleUser = 'user';

/// Chat role of the model's answers.
const String _roleAssistant = 'assistant';

/// How the model must work, before the date and account focus are added.
const String _instructions = '''
You are the assistant inside fMoney, a personal finance app. You answer questions about the user's own accounts and transactions by calling the tools: never guess a number, an id or a name, look it up.
- Get ids first: list_accounts for accounts, list_categories and list_payees for categories and payees.
- The user's names are approximate: look things up by single keywords (e.g. "condo", not "Quebec Condo Asset"), and try other keywords and the matching accounts, categories and payees before saying nothing matches.
- Transfers between accounts are found with the other account's name: search_transactions with account_ids of one account and text naming the other.
- search_transactions covers every year, not only recent ones. Use summarize_transactions for totals ("how much").
- When the rows matter, call show_transactions (or open_view) so the user gets a button that opens them in the app, rather than listing many rows.
- set_category, link_transfer, merge_payees and create_alias only propose a change: the user confirms each one in a dialog, and every change stays pending until the user saves. Never say anything was saved, and do not retry a change the user declined.
- Answer concisely, in the language of the question, with dates, amounts and account names.''';

/// Returns the messages that open a tool conversation: the instructions (with today's date and the accounts
/// the user selected as focus, or all of them when [focusedAccounts] is empty), the [history] as plain
/// turns, then [question].
List<Map<String, dynamic>> aiToolConversationStart({
  required String question,
  required List<ChatMessage> history,
  required List<Account> focusedAccounts,
}) {
  final String focus = focusedAccounts.isEmpty
      ? 'The user has not narrowed the accounts: consider all of them.'
      : 'The user selected these accounts as focus; search others too when the question needs it: '
            '${focusedAccounts.map((Account a) => '${a.fieldName.value} (id ${a.uniqueId})').join(', ')}.';
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'role': _roleSystem,
      'content': '$_instructions\nToday is ${dateToString(DateTime.now())}.\n$focus',
    },
    for (final ChatMessage message in history)
      <String, dynamic>{
        'role': message.type == ChatFrom.user ? _roleUser : _roleAssistant,
        'content': message.message,
      },
    <String, dynamic>{'role': _roleUser, 'content': question},
  ];
}
