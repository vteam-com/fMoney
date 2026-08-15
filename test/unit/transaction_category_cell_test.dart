import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_delegate_utils.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';

void main() {
  setUp(() {
    // Wires DataAccess.trackMutations and the category suggestion provider.
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  group('transactionBuildCategoryCellWidget', () {
    test('takes the fast path when no suggestion, category set and no splits', () {
      final Category category = Category(
        id: -1,
        name: 'Groceries',
        type: CategoryType.expense,
      );
      Data().categories.appendNewMoneyObject(category, fireNotification: false);

      final Transaction transaction = Transaction(date: DateTime(2024, 1, 1));
      transaction.fieldCategoryId.value = category.uniqueId;

      final Widget cell = transactionBuildCategoryCellWidget(transaction);

      // The fast path is a plain non-interactive row.
      expect(cell, isA<Row>());
    });

    test('uses the suggestion wrapper when the category is not set', () {
      final Transaction transaction = Transaction(date: DateTime(2024, 1, 2));

      final Widget cell = transactionBuildCategoryCellWidget(transaction);

      // The interactive path is provided by the suggestion provider.
      expect(cell, isNot(isA<Row>()));
    });
  });
}
