// ignore_for_file: unnecessary_this
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/shared/domain/category.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/transaction.dart';
import 'package:money/shared/presentation/app_scope.dart';
import 'package:money/widgets/pure/scale_down.dart';
import 'package:money/widgets/sankey/sankey_painter.dart';
import 'package:money/widgets/state/theme_controller.dart';

const double _zeroDouble = 0.0;
const double _containerPadding = 8.0;
const double _minHeight = 1000.0;

/// A stateless widget for sankey panel.
class SankeyPanel extends StatelessWidget {
  const SankeyPanel({required this.minYear, required this.maxYear, super.key});

  final int maxYear;

  final int minYear;

  @override
  Widget build(final BuildContext context) {
    final ({List<SanKeyEntry> incomes, List<SanKeyEntry> expenses}) sankeyData = _transformData();
    final ThemeController themeController = AppScope.of(context).themeController;
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            width: constraints.maxWidth,
            height: max(constraints.maxHeight, _minHeight),
            padding: const EdgeInsets.all(_containerPadding),
            child: SankeyWidget(
              leftEntries: sankeyData.incomes,
              rightEntries: sankeyData.expenses,
              compactView: context.isWidthSmall,
              colors: SankeyColors(
                darkTheme: themeController.isDarkTheme,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Transforms transactions in the selected year range into Sankey income/expense entries.
  ({List<SanKeyEntry> incomes, List<SanKeyEntry> expenses}) _transformData() {
    final Map<Category, double> mapOfExpenses = <Category, double>{};
    final Map<Category, double> mapOfIncomes = <Category, double>{};
    final List<SanKeyEntry> sanKeyListOfExpenses = <SanKeyEntry>[];
    final List<SanKeyEntry> sanKeyListOfIncomes = <SanKeyEntry>[];

    final Iterable<Transaction> transactions = Data().transactions.transactionInYearRange(
      minYear: minYear,
      maxYear: maxYear,
      incomesOrExpenses: null,
    );

    for (final Transaction element in transactions) {
      final Category? category = Data().categories.get(
        element.fieldCategoryId.value,
      );
      if (category != null) {
        switch (category.fieldType.value) {
          case CategoryType.income:
          case CategoryType.saving:
          case CategoryType.investment:
            final Category topCategory = Data().categories.getTopAncestor(
              category,
            );
            double? mapValue = mapOfIncomes[topCategory];
            mapValue ??= _zeroDouble;
            mapOfIncomes[topCategory] = mapValue + element.fieldAmount.value.asDouble();
            break;
          case CategoryType.expense:
          case CategoryType.recurringExpense:
            final Category topCategory = Data().categories.getTopAncestor(
              category,
            );
            double? mapValue = mapOfExpenses[topCategory];
            mapValue ??= _zeroDouble;
            mapOfExpenses[topCategory] = mapValue + element.fieldAmount.value.asDouble();
            break;
          default:
            break;
        }
      }
    }

    // Clean up the Incomes, drop 0.00
    mapOfIncomes.removeWhere((final Category _, final double v) => v <= _zeroDouble);
    // Sort Descending
    final Map<Category, double> sortedIncomes = Map<Category, double>.fromEntries(
      mapOfIncomes.entries.toList()..sort(
        (
          final MapEntry<Category, double> e1,
          final MapEntry<Category, double> e2,
        ) => (e2.value - e1.value).toInt(),
      ),
    );

    sortedIncomes.forEach((final Category key, final double value) {
      sanKeyListOfIncomes.add(
        SanKeyEntry()
          ..name = key.fieldName.value
          ..value = value,
      );
    });

    // Clean up the Expenses, drop 0.00
    mapOfExpenses.removeWhere((final Category _, final double v) => v == _zeroDouble);

    // Sort Ascending, in the case of expenses that means the largest negative number to the least negative number
    final Map<Category, double> sortedExpenses = Map<Category, double>.fromEntries(
      mapOfExpenses.entries.toList()..sort(
        (
          final MapEntry<Category, double> e1,
          final MapEntry<Category, double> e2,
        ) => (e1.value - e2.value).toInt(),
      ),
    );

    sortedExpenses.forEach((final Category key, final double value) {
      sanKeyListOfExpenses.add(
        SanKeyEntry()
          ..name = key.fieldName.value
          ..value = value,
      );
    });

    return (incomes: sanKeyListOfIncomes, expenses: sanKeyListOfExpenses);
  }
}
