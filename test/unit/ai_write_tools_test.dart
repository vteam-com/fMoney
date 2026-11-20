import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';
import 'package:money/views/home/ai/tools/ai_write_tools_helper.dart';

import '../helpers/ai_tools_fixture_helper.dart';
import '../helpers/test_fixtures_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Account bank;
  late Account savings;
  late Category condoFees;
  late List<String> summaries;

  /// The write tools, with a dialog the user answers with [apply]; each summary shown lands in [summaries].
  List<AiTool> tools({required bool apply}) =>
      aiWriteTools(({required String summary, required List<String> details}) async {
        summaries.add(summary);
        return apply;
      });

  setUp(() {
    resetTestData();
    bank = createTestAccount('Bank');
    savings = createTestAccount('Savings');
    condoFees = createAiTestCategory('House:Condo Fees');
    summaries = <String>[];
  });

  group('set_category', () {
    test('changes nothing when the user declines', () async {
      final Transaction t = createAiTestTransaction(bank, payee: 'HOA', amount: -488, date: DateTime(2026, 3, 2));

      final Map<String, dynamic> result = await runAiTool(tools(apply: false), 'set_category', <String, dynamic>{
        'transaction_ids': <int>[t.uniqueId],
        'category': 'House:Condo Fees',
      });

      expect(result['applied'], isFalse);
      expect(t.fieldCategoryId.value, -1);
      expect(t.mutation, MutationType.none);
      expect(summaries.single, contains('House:Condo Fees'));
    });

    test('applies as a pending edit, left unsaved, when the user agrees', () async {
      final Transaction t = createAiTestTransaction(bank, payee: 'HOA', amount: -488, date: DateTime(2026, 3, 2));
      DataAccess.trackMutations.reset();

      final Map<String, dynamic> result = await runAiTool(tools(apply: true), 'set_category', <String, dynamic>{
        'transaction_ids': '${t.uniqueId}',
        'category': 'house:condo fees',
      });

      expect(result['applied'], isTrue);
      expect(result['note'], contains('nothing is saved'));
      expect(t.fieldCategoryId.value, condoFees.uniqueId);
      expect(t.mutation, MutationType.changed);
      expect(DataAccess.trackMutations.isMutated(), isTrue);
    });

    test('names similar categories when the category does not exist', () async {
      final Transaction t = createAiTestTransaction(bank, payee: 'HOA', amount: -488, date: DateTime(2026, 3, 2));

      expect(
        () => runAiTool(tools(apply: true), 'set_category', <String, dynamic>{
          'transaction_ids': <int>[t.uniqueId],
          'category': 'Condo',
        }),
        throwsA(isA<ArgumentError>().having((ArgumentError e) => e.message, 'message', contains('House:Condo Fees'))),
      );
      expect(summaries, isEmpty);
    });
  });

  group('link_transfer', () {
    test('refuses two transactions of the same account without asking', () async {
      final Transaction a = createAiTestTransaction(bank, payee: 'x', amount: -10, date: DateTime(2025));
      final Transaction b = createAiTestTransaction(bank, payee: 'x', amount: 10, date: DateTime(2025));

      expect(
        () => runAiTool(tools(apply: true), 'link_transfer', <String, dynamic>{
          'transaction_id': a.uniqueId,
          'other_transaction_id': b.uniqueId,
        }),
        throwsArgumentError,
      );
      expect(summaries, isEmpty);
    });

    test('links opposite amounts in two accounts when the user agrees', () async {
      final Transaction a = createAiTestTransaction(bank, payee: 'x', amount: -10, date: DateTime(2025));
      final Transaction b = createAiTestTransaction(savings, payee: 'x', amount: 10, date: DateTime(2025));

      await runAiTool(tools(apply: true), 'link_transfer', <String, dynamic>{
        'transaction_id': a.uniqueId,
        'other_transaction_id': b.uniqueId,
      });

      expect(a.isTransfer && b.isTransfer, isTrue);
      expect(a.mutation, MutationType.changed);
    });
  });

  test('merge_payees moves the transactions and removes the emptied payee', () async {
    final Transaction t = createAiTestTransaction(bank, payee: 'AMZN Mktp', amount: -20, date: DateTime(2025));
    final Payee from = Data().payees.getByName('AMZN Mktp')!;
    final Payee to = Data().getOrCreatePayee('Amazon', fireNotification: false);

    final Map<String, dynamic> result = await runAiTool(tools(apply: true), 'merge_payees', <String, dynamic>{
      'from_payee_ids': <int>[from.uniqueId],
      'to_payee_id': to.uniqueId,
    });

    expect(result['changed'], 1);
    expect(t.fieldPayee.value, to.uniqueId);
    expect(from.mutation, MutationType.deleted);
  });

  group('create_alias', () {
    test('adds the alias and renames the transactions whose bank text it matches', () async {
      final Transaction t = createAiTestTransaction(bank, payee: 'AMZN MKTP CA', amount: -20, date: DateTime(2025));
      final Payee amazon = Data().getOrCreatePayee('Amazon', fireNotification: false);

      final Map<String, dynamic> result = await runAiTool(tools(apply: true), 'create_alias', <String, dynamic>{
        'pattern': 'amzn mktp ca',
        'payee_id': amazon.uniqueId,
      });

      expect(result['changed'], 1);
      expect(t.fieldPayee.value, amazon.uniqueId);
      expect(Data().aliases.iterableList().map((Alias a) => a.fieldPattern.value), contains('amzn mktp ca'));
      expect(summaries.single, contains('(1)'));
    });

    test('rejects an invalid regular expression without asking', () async {
      final Payee amazon = Data().getOrCreatePayee('Amazon', fireNotification: false);

      expect(
        () => runAiTool(tools(apply: true), 'create_alias', <String, dynamic>{
          'pattern': 'AMZN(',
          'payee_id': amazon.uniqueId,
          'is_regex': true,
        }),
        throwsArgumentError,
      );
      expect(summaries, isEmpty);
    });
  });
}
