import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/ai_chat_action_model.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/home/ai/tools/ai_analysis_tools_helper.dart';
import 'package:money/views/home/ai/tools/ai_data_tools_helper.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';
import 'package:money/views/home/ai/tools/ai_ui_hook_tools_helper.dart';

import '../helpers/ai_tools_fixture_helper.dart';
import '../helpers/test_fixtures_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Account bank;
  late Account condo;
  late Category utilities;
  late Transaction purchase;
  late Transaction purchaseInAsset;
  late Transaction hydro;
  final List<AiTool> tools = <AiTool>[...aiDataTools(), ...aiAnalysisTools()];

  setUp(() {
    resetTestData();
    // Test accounts start with every flag set, closed included.
    bank = createTestAccount('Canada:CIBC Condo')
      ..fieldType.value = AccountType.checking
      ..isOpen = true;
    condo = createTestAccount('RealEstate:Quebec:Condo')
      ..fieldType.value = AccountType.asset
      ..isOpen = true;
    utilities = createAiTestCategory('House:Utilities');
    purchase = createAiTestTransaction(bank, payee: '', amount: -235007.5, date: DateTime(2014, 3, 6));
    purchaseInAsset = createAiTestTransaction(condo, payee: '', amount: 235007.5, date: DateTime(2014, 3, 6));
    Data().convertDisconnectedTransactionsToTransfer(transaction: purchase, relatedTransaction: purchaseInAsset);
    hydro = createAiTestTransaction(
      bank,
      payee: 'Hydro Quebec',
      amount: -50,
      date: DateTime(2024, 1, 15),
      category: utilities,
    );
  });

  group('search_transactions', () {
    test('finds a transfer by the other account name, in any year, but not by its own account name', () async {
      final Map<String, dynamic> byOther = await runAiTool(tools, 'search_transactions', <String, dynamic>{
        'account_ids': <int>[bank.uniqueId],
        'text': 'realestate',
      });
      expect(byOther['total_matches'], 1);
      expect(byOther['rows'][0]['id'], purchase.uniqueId);
      expect(byOther['rows'][0]['transfer_account'], 'RealEstate:Quebec:Condo');

      final Map<String, dynamic> byOwn = await runAiTool(tools, 'search_transactions', <String, dynamic>{
        'account_ids': <int>[bank.uniqueId],
        'text': 'cibc',
      });
      expect(byOwn['total_matches'], 0);
    });

    test('filters by date and amount, sorts, caps the rows and reports the total', () async {
      final Map<String, dynamic> recent = await runAiTool(tools, 'search_transactions', <String, dynamic>{
        'date_from': '2024-01-01',
      });
      expect((recent['rows'] as List<dynamic>).map((dynamic r) => r['id']), <int>[hydro.uniqueId]);

      final Map<String, dynamic> utilityBills = await runAiTool(tools, 'search_transactions', <String, dynamic>{
        'category': 'UTILITIES',
      });
      expect((utilityBills['rows'] as List<dynamic>).map((dynamic r) => r['id']), <int>[hydro.uniqueId]);

      final Map<String, dynamic> large = await runAiTool(tools, 'search_transactions', <String, dynamic>{
        'min_amount': '1000',
      });
      expect(large['total_matches'], 2);

      final Map<String, dynamic> oldestOnly = await runAiTool(tools, 'search_transactions', <String, dynamic>{
        'sort': 'date_asc',
        'limit': 1,
      });
      expect(oldestOnly['total_matches'], 3);
      expect((oldestOnly['rows'] as List<dynamic>).length, 1);
      expect(oldestOnly['rows'][0]['date'], '2014-03-06');
      expect(oldestOnly['note'], contains('narrow'));
    });
  });

  test('summarize_transactions totals per year', () async {
    final Map<String, dynamic> summary = await runAiTool(tools, 'summarize_transactions', <String, dynamic>{
      'group_by': 'year',
    });
    expect(summary['groups'], <Map<String, Object>>[
      <String, Object>{'key': '2014', 'count': 2, 'total': 0.0},
      <String, Object>{'key': '2024', 'count': 1, 'total': -50.0},
    ]);
  });

  test('list_accounts lists closed accounts only when asked', () async {
    createTestAccount('Old savings').isOpen = false;
    final Map<String, dynamic> open = await runAiTool(tools, 'list_accounts', <String, dynamic>{});
    final Map<String, dynamic> all = await runAiTool(tools, 'list_accounts', <String, dynamic>{'include_closed': true});
    expect(open['total_matches'], 2);
    expect(all['total_matches'], 3);
  });

  test('get_transaction explains an unknown id', () async {
    expect(
      () => runAiTool(tools, 'get_transaction', <String, dynamic>{'id': 999}),
      throwsA(isA<ArgumentError>().having((ArgumentError e) => e.message, 'message', contains('search_transactions'))),
    );
  });

  test('find_transfer_matches lists the opposite amount in another account', () async {
    final Account savings = createTestAccount('Savings');
    final Transaction out = createAiTestTransaction(bank, payee: 'Me', amount: -300, date: DateTime(2025, 2, 1));
    final Transaction into = createAiTestTransaction(savings, payee: 'Me', amount: 300, date: DateTime(2025, 2, 2));

    final Map<String, dynamic> result = await runAiTool(tools, 'find_transfer_matches', <String, dynamic>{
      'transaction_id': out.uniqueId,
    });
    expect((result['candidates'] as List<dynamic>).map((dynamic r) => r['id']), <int>[into.uniqueId]);
  });

  group('UI hooks', () {
    test('show_transactions adds a button filtered by account, category and dates', () async {
      final List<AiChatAction> actions = <AiChatAction>[];
      await runAiTool(aiUiHookTools(actions), 'show_transactions', <String, dynamic>{
        'label': 'Utilities',
        'account_ids': <int>[bank.uniqueId],
        'category': 'utilities',
        'date_from': '2024-01-01',
        'text': 'hydro',
      });

      final AiChatAction action = actions.single;
      expect(action.viewId, ViewId.viewTransactions);
      expect(action.textFilter, 'hydro');
      final Map<String, FieldFilter> filters = <String, FieldFilter>{
        for (final FieldFilter filter in action.columnFilters.list) filter.fieldName: filter,
      };
      expect(filters[columnIdAccount]!.strings, <String>['Canada:CIBC Condo']);
      expect(filters[columnIdCategory]!.strings, <String>['House:Utilities']);
      expect(filters[columnIdDate]!.byDateRange, isTrue);
      expect(filters[columnIdDate]!.strings.first, '2024-01-01');
    });

    test('open_view adds a button for a known view and rejects others', () async {
      final List<AiChatAction> actions = <AiChatAction>[];
      final List<AiTool> hooks = aiUiHookTools(actions);
      await runAiTool(hooks, 'open_view', <String, dynamic>{'label': 'Payees', 'view': 'payees', 'select_id': 4});
      expect(actions.single.viewId, ViewId.viewPayees);
      expect(actions.single.selectedId, 4);
      expect(
        () => runAiTool(hooks, 'open_view', <String, dynamic>{'label': 'x', 'view': 'nowhere'}),
        throwsArgumentError,
      );
    });

    test('a button survives the saved chat history', () {
      final AiChatAction action = AiChatAction(
        label: 'Condo',
        viewId: ViewId.viewAccounts,
        selectedId: 3,
        textFilter: 'x',
      );
      final AiChatAction restored = AiChatAction.fromJson(action.toJson());
      expect(restored.toJson(), action.toJson());
    });
  });
}
