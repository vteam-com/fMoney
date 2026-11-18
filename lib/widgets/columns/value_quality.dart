// ignore: fcheck_one_class_per_file

import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/components/semantic_text_widget.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _sortByDate = 0;
const int _sortByDescription = 1;
const int _sortByAmount = 2;

/// Callback function type that returns the existing transaction matching an imported row, or null.
/// Rows already in [alreadyMatched] must not be returned again, so one existing
/// transaction is matched by at most one imported row.
/// This allows the value_parser.dart to be decoupled from data.dart dependencies.
typedef TransactionExistsCallback = Object? Function({
  required int accountId,
  required DateTime dateTime,
  required double amount,
  required String fitid,
  required Set<Object> alreadyMatched,
});

/// Represents value quality.
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

  /// Parses the stored string as a monetary amount with currency and sign handling.
  double asAmount() => (parseAmount(valueAsString, currency) ?? 0.00) * (reverseAmountValue ? -1 : 1);

  /// Parses the stored string as a DateTime using the configured date format.
  DateTime? asDate() {
    if (valueAsString.isEmpty) {
      return null;
    }
    return DateFormat(dateFormat).tryParse(valueAsString);
  }

  /// Returns the raw stored string value.
  String asString() => valueAsString;

  /// Builds a styled amount widget or warning if parsing fails.
  Widget valueAsAmountWidget(BuildContext? context) {
    if (valueAsString.isEmpty) {
      return buildWarning(context, SharedStrings.placeholderNoAmount);
    }

    final double? amount = parseAmount(valueAsString, currency);
    if (amount == null) {
      return buildWarning(context, valueAsString);
    }

    final AmountModel mm = AmountModel(amount: asAmount(), iso4217: currency);
    return WidgetFromData(amountModel: mm);
  }

  /// Builds a styled date widget or warning if parsing fails.
  Widget valueAsDateWidget(BuildContext? context) {
    if (valueAsString.isEmpty) {
      return buildWarning(context, SharedStrings.placeholderNoDate);
    }

    final DateTime? parsedDate = asDate();
    if (parsedDate == null) {
      return buildWarning(context, valueAsString);
    }

    final String dateText = DateFormat('yyyy-MM-dd').format(parsedDate);
    return SelectableText(dateText);
  }

  /// Builds a selectable text widget for the value, or a warning if empty.
  Widget valueAsTextWidget(BuildContext? context) {
    if (valueAsString.isEmpty) {
      return buildWarning(context, SharedStrings.placeholderNoDescription);
    }
    return SelectableText(valueAsString);
  }
}

/// Represents values quality.
class ValuesQuality {
  ValuesQuality({
    required this.date,
    required this.description,
    required this.amount,
    this.reverseAmountValue = false,
    this.stockSymbol = '',
    this.stockAction = '',
    this.stockQuantity = 0.0,
    this.stockPrice = 0.0,
    this.fitid = '',
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
  final String stockSymbol;
  final String stockAction;
  final double stockQuantity;
  final double stockPrice;

  /// Financial institution transaction id of the imported row, empty when unknown.
  final String fitid;

  bool exist = false;

  @override
  String toString() => '$date; $description; $amount';

  /// Returns whether this entry has stock/investment information.
  bool hasStockInfo() {
    return stockSymbol.isNotEmpty || stockAction.isNotEmpty || stockQuantity != 0 || stockPrice > 0;
  }

  /// True when the date and amount parse and the description is not blank.
  bool get isValid =>
      date.asDate() != null &&
      parseAmount(amount.valueAsString, amount.currency) != null &&
      description.valueAsString.trim().isNotEmpty;

  /// Checks whether this value set already exists as a transaction for the given account.
  /// A matched transaction is added to [alreadyMatched] so no other row can claim it.
  bool checkIfExistAlready({
    required int accountId,
    required TransactionExistsCallback transactionExistsCallback,
    required Set<Object> alreadyMatched,
  }) {
    final DateTime? parsedDate = date.asDate();
    if (parsedDate == null) {
      exist = false;
      return exist;
    }
    final Object? match = transactionExistsCallback(
      accountId: accountId,
      dateTime: parsedDate,
      amount: amount.asAmount(),
      fitid: fitid,
      alreadyMatched: alreadyMatched,
    );
    if (match != null) {
      alreadyMatched.add(match);
    }
    exist = match != null;
    return exist;
  }

  /// Returns the date range covered by a list of values.
  static DateRange getDateRange(List<ValuesQuality> list) {
    final DateRange range = DateRange();
    for (final ValuesQuality v in list) {
      range.inflate(v.date.asDate());
    }
    return range;
  }

  /// Sorts a list of values by date, description, or amount.
  static void sort(
    List<ValuesQuality> list,
    int sortBy,
    bool ascending,
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
