// ignore_for_file: unnecessary_this
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/data/entities/category.dart';
import 'package:money/data/entities/transaction.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/widgets/pure/scale_down.dart';
import 'package:money/widgets/sankey/__sankey_painter.dart';
import 'package:money/widgets/theme_controller.dart';

const double _zeroDouble = 0.0;
const double _panelPadding = 10.0;
const double _containerPadding = 8.0;
const double _minHeight = 1000.0;

// ignore: must_be_immutable
/// A stateless widget for sankey panel.
class SankeyPanel extends StatelessWidget {
  SankeyPanel({required this.minYear, required this.maxYear, super.key});

  late Map<Category, double> mapOfExpenses = <Category, double>{};

  late Map<Category, double> mapOfIncomes = <Category, double>{};

  final int maxYear;

  final int minYear;

  late double padding = _panelPadding;

  late List<SanKeyEntry> sanKeyListOfExpenses = <SanKeyEntry>[];

  late List<SanKeyEntry> sanKeyListOfIncomes = <SanKeyEntry>[];

  late double totalExpenses = _zeroDouble;

  late double totalHeight = _zeroDouble;

  late double totalIncomes = _zeroDouble;

  late double totalInvestments = _zeroDouble;

  late double totalNones = _zeroDouble;

  late double totalSavings = _zeroDouble;

  @override
  Widget build(final BuildContext context) {
    transformData();
    final ThemeController themeController = Get.find();
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            width: constraints.maxWidth,
            height: max(constraints.maxHeight, _minHeight),
            padding: const EdgeInsets.all(_containerPadding),
            child: SankeyWidget(
              leftEntries: sanKeyListOfIncomes,
              rightEntries: sanKeyListOfExpenses,
              compactView: context.isWidthSmall,
              colors: SankeyColors(
                darkTheme: themeController.isDarkTheme.value,
              ),
            ),
          ),
        );
      },
    );
  }

  void transformData() {
    final Iterable<Transaction> transactions = Data().transactions.transactionInYearRange(
      minYear: minYear,
      maxYear: maxYear,
      incomesOrExpenses: null,
    );

    for (Transaction element in transactions) {
      final Category? category = Data().categories.get(
        element.fieldCategoryId.value,
      );
      if (category != null) {
        switch (category.fieldType.value) {
          case CategoryType.income:
          case CategoryType.saving:
          case CategoryType.investment:
            totalIncomes += element.fieldAmount.value.asDouble();

            final Category topCategory = Data().categories.getTopAncestor(
              category,
            );
            double? mapValue = mapOfIncomes[topCategory];
            mapValue ??= _zeroDouble;
            mapOfIncomes[topCategory] = mapValue + element.fieldAmount.value.asDouble();
            break;
          case CategoryType.expense:
          case CategoryType.recurringExpense:
            totalExpenses += element.fieldAmount.value.asDouble();
            final Category topCategory = Data().categories.getTopAncestor(
              category,
            );
            double? mapValue = mapOfExpenses[topCategory];
            mapValue ??= _zeroDouble;
            mapOfExpenses[topCategory] = mapValue + element.fieldAmount.value.asDouble();
            break;
          default:
            totalNones += element.fieldAmount.value.asDouble();
            break;
        }
      }
    }

    // Clean up the Incomes, drop 0.00
    mapOfIncomes.removeWhere((final Category _, final double v) => v <= _zeroDouble);
    // Sort Descending
    mapOfIncomes = Map<Category, double>.fromEntries(
      mapOfIncomes.entries.toList()..sort(
        (
          final MapEntry<Category, double> e1,
          final MapEntry<Category, double> e2,
        ) => (e2.value - e1.value).toInt(),
      ),
    );

    mapOfIncomes.forEach((final Category key, final double value) {
      sanKeyListOfIncomes.add(
        SanKeyEntry()
          ..name = key.fieldName.value
          ..value = value,
      );
    });

    // Clean up the Expenses, drop 0.00
    mapOfExpenses.removeWhere((final Category _, final double v) => v == _zeroDouble);

    // Sort Ascending, in the case of expenses that means the largest negative number to the least negative number
    mapOfExpenses = Map<Category, double>.fromEntries(
      mapOfExpenses.entries.toList()..sort(
        (
          final MapEntry<Category, double> e1,
          final MapEntry<Category, double> e2,
        ) => (e1.value - e2.value).toInt(),
      ),
    );

    mapOfExpenses.forEach((final Category key, final double value) {
      sanKeyListOfExpenses.add(
        SanKeyEntry()
          ..name = key.fieldName.value
          ..value = value,
      );
    });

    final double heightNeededToRenderIncomes = getHeightNeededToRender(
      sanKeyListOfIncomes,
    );
    final double heightNeededToRenderExpenses = getHeightNeededToRender(
      sanKeyListOfExpenses,
    );
    totalHeight = max(
      heightNeededToRenderIncomes,
      heightNeededToRenderExpenses,
    );
  }
}
