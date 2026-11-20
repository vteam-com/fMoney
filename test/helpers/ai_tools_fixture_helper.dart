import 'dart:convert';

import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';

import 'test_fixtures_helper.dart';

/// Creates and appends a category named [name] of [type].
Category createAiTestCategory(String name, [CategoryType type = CategoryType.expense]) {
  return Data().categories.appendNewMoneyObject(
    Category(id: -1, name: name, type: type, data: Data()),
    fireNotification: false,
  ) as Category;
}

/// Creates and appends a transaction of [amount] on [date] in [account] for [payee], in [category], with [memo],
/// unchanged as if loaded from the file, so later edits show as pending changes.
Transaction createAiTestTransaction(
  Account account, {
  required String payee,
  required double amount,
  required DateTime date,
  Category? category,
  String memo = '',
}) {
  final Transaction transaction = createTestTransaction(account, payee, category: category);
  transaction.fieldAmount.value.setAmount(amount);
  transaction.fieldDateTime.value = date;
  transaction.fieldMemo.value = memo;
  transaction.mutation = MutationType.none;
  return transaction;
}

/// Runs the tool named [name] from [tools] on [args] and returns its result as decoded JSON.
Future<Map<String, dynamic>> runAiTool(List<AiTool> tools, String name, Map<String, dynamic> args) async {
  final Object? result = await tools.firstWhere((AiTool tool) => tool.name == name).run(args);
  return jsonDecode(jsonEncode(result)) as Map<String, dynamic>;
}
