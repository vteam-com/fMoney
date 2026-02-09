// ignore: fcheck_one_class_per_file

import 'package:flutter/material.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/widgets/semantic_text.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _sortByDate = 0;
const int _sortByDescription = 1;
const int _sortByAmount = 2;

/// Callback function type for checking if a transaction already exists in the system.
/// This allows the value_parser.dart to be decoupled from data.dart dependencies.
typedef TransactionExistsCallback =
    bool Function({
      required int accountId,
      required DateTime dateTime,
      required double amount,
    });

class ValueQuality {
  const ValueQuality(
    this.valueAsString, {
    this.dateFormat = 'MM/DD/YYYY',
    this.currency = Constants.defaultCurrency,
    this.reverseAmountValue = false,
  });

  final String currency;
  final String dateFormat;
  final bool reverseAmountValue;
  final String valueAsString;

  @override
  String toString() => asString();

  double asAmount() => (parseAmount(valueAsString, currency) ?? 0.00) * (reverseAmountValue ? -1 : 1);

  DateTime? asDate() {
    if (valueAsString.isEmpty) {
      return null;
    }
    return DateFormat(dateFormat).tryParse(valueAsString);
  }

  String asString() => valueAsString;

  Widget valueAsAmountWidget(final BuildContext? context) {
    if (valueAsString.isEmpty) {
      return buildWarning(context, '< no amount >');
    }

    final double? amount = parseAmount(valueAsString, currency);
    if (amount == null) {
      return buildWarning(context, valueAsString);
    }

    final AmountModel mm = AmountModel(amount: asAmount(), iso4217: currency);
    return WidgetFromData(amountModel: mm);
  }

  Widget valueAsDateWidget(final BuildContext? context) {
    if (valueAsString.isEmpty) {
      return buildWarning(context, '< no date >');
    }

    final DateTime? parsedDate = asDate();
    if (parsedDate == null) {
      return buildWarning(context, valueAsString);
    }

    final String dateText = DateFormat('yyyy-MM-dd').format(parsedDate);
    return SelectableText(dateText);
  }

  Widget valueAsTextWidget(final BuildContext? context) {
    if (valueAsString.isEmpty) {
      return buildWarning(context, '< no description >');
    }
    return SelectableText(valueAsString);
  }
}

class ValuesQuality {
  ValuesQuality({
    required this.date,
    required this.description,
    required this.amount,
    this.reverseAmountValue = false,
  });

  factory ValuesQuality.empty() => ValuesQuality(
    date: const ValueQuality(''),
    description: const ValueQuality(''),
    amount: const ValueQuality(''),
  );

  final ValueQuality amount;
  final ValueQuality date;
  final ValueQuality description;
  final bool reverseAmountValue;

  bool exist = false;

  @override
  String toString() => '$date; $description; $amount';

  bool checkIfExistAlready({
    required final int accountId,
    required TransactionExistsCallback transactionExistsCallback,
  }) {
    exist = isTransactionAlreadyInTheSystem(
      accountId: accountId,
      dateTime: date.asDate() ?? DateTime.now(),
      amount: amount.asAmount(),
      transactionExistsCallback: transactionExistsCallback,
    );
    return exist;
  }

  static DateRange getDateRange(final List<ValuesQuality> list) {
    final DateRange range = DateRange();
    for (final ValuesQuality v in list) {
      range.inflate(v.date.asDate());
    }
    return range;
  }

  static void sort(
    final List<ValuesQuality> list,
    final int sortBy,
    final bool ascending,
  ) {
    list.sort((ValuesQuality a, ValuesQuality b) {
      switch (sortBy) {
        case _sortByDate:
          return sortByDate(a.date.asDate(), b.date.asDate(), ascending);
        case _sortByDescription:
          return sortByString(
            a.description.asString(),
            b.description.asString(),
            ascending,
          );
        case _sortByAmount:
          return sortByValue(
            a.amount.asAmount(),
            b.amount.asAmount(),
            ascending,
          );
      }
      return 0;
    });
  }
}

bool isTransactionAlreadyInTheSystem({
  required final int accountId,
  required final DateTime dateTime,
  required final double amount,
  required TransactionExistsCallback transactionExistsCallback,
}) => transactionExistsCallback(
  accountId: accountId,
  dateTime: dateTime,
  amount: amount,
);
