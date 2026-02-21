import 'dart:math';

import 'package:flutter/material.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/widgets/semantic_text.dart';
import 'package:money/widgets/value_quality.dart';

const int _threeColumnSeparatorCount = 2;
const int _twoValueCount = 2;
const int _expectedTripleCount = 3;
const double _dateColumnWidth = 100;
const double _descriptionColumnWidth = 300;
const double _amountColumnWidth = 100;

/// The `ValuesParser` class is responsible for parsing input data and extracting
/// relevant values from it. It provides methods for parsing, transforming, and
/// validating the extracted values.
class ValuesParser {
  ValuesParser({
    required this.dateFormat,
    required this.currency,
    this.reverseAmountValue = false,
  });

  final String currency; // USD, EUR
  final String dateFormat;
  final bool reverseAmountValue;

  String errorMessage = '';
  List<Widget> rows = <Widget>[];

  List<ValuesQuality> _values = <ValuesQuality>[];

  /// Adds a parsed [ValuesQuality] item to the internal list.
  void add(final ValuesQuality item) {
    _values.add(item);
  }

  /// Interleaves three column strings into a single semicolon-separated buffer.
  static String assembleIntoSingleTextBuffer(
    final String multiStringDates,
    final String multiStringDescriptions,
    final String multiStringAmounts,
  ) {
    int maxLines = 0;
    List<String> dates = multiStringDates.split('\n');
    maxLines = max(maxLines, dates.length);
    List<String> descriptions = multiStringDescriptions.split('\n');
    maxLines = max(maxLines, descriptions.length);
    List<String> amounts = multiStringAmounts.split('\n');
    maxLines = max(maxLines, amounts.length);

    // Make them all the same length
    dates = padList(dates, maxLines, '');
    descriptions = padList(descriptions, maxLines, '');
    amounts = padList(amounts, maxLines, '');

    String singleText = '';
    for (int line = 0; line < maxLines; line++) {
      singleText += '${dates[line]}; ${descriptions[line]}; ${amounts[line]}\n';
    }
    return singleText;
  }

  /// Attempts to parse a line into date/description/amount triple.
  ValuesQuality attemptToExtractTriples(String line) {
    String dateAsText = '';
    String descriptionAsText = '';
    String amountAsText = '';

    line.trim();
    final List<String> threeValues = line
        .split(RegExp(r'\t|;|\|'))
        .where((String token) => token.trim().isNotEmpty)
        .toList();

    // We are looking for these 3 values
    // Date | Description | Amount
    switch (threeValues.length) {
      // no value
      case 0:
        return ValuesQuality.empty();

      // Only one value
      case 1:
        dateAsText = threeValues.first;

      // Only two values
      case _twoValueCount:
        dateAsText = threeValues.first;
        descriptionAsText = threeValues[1];

      // Perfect
      case _expectedTripleCount:
      default: // 4 or more
        dateAsText = threeValues.first;
        descriptionAsText = threeValues.sublist(1, threeValues.length - 1).join(' ');
        amountAsText = cleanString(threeValues.last, '-+0123456789(),.');
    }

    return ValuesQuality(
      // date
      date: ValueQuality(dateAsText.trim(), dateFormat: dateFormat),

      // description
      description: ValueQuality(descriptionAsText.trim()),

      // amount
      amount: ValueQuality(
        amountAsText.trim(),
        currency: currency,
        reverseAmountValue: reverseAmountValue,
      ),
      reverseAmountValue: reverseAmountValue,
    );
  }

  /// Builds a columnar presentation widget for all parsed lines.
  Widget buildPresentation(final BuildContext context) {
    final List<Widget> rows = <Widget>[];

    if (lines.isNotEmpty) {
      for (ValuesQuality line in lines) {
        rows.add(
          Row(
            children: <Widget>[
              SizedBox(
                width: _dateColumnWidth,
                child: line.date.valueAsDateWidget(context),
              ),
              // Date
              SizedBox(
                width: _descriptionColumnWidth,
                child: line.description.valueAsTextWidget(context),
              ),
              // Description
              SizedBox(
                width: _amountColumnWidth,
                child: line.amount.valueAsAmountWidget(context),
              ),
              // Amount
            ],
          ),
        );
      }
    }

    return rows.isEmpty
        ? buildWarning(context, 'Not input text')
        : Column(mainAxisAlignment: MainAxisAlignment.start, children: rows);
  }

  /// Parses raw input text into a list of ValuesQuality transactions.
  void convertInputTextToTransactionList(
    final BuildContext? _,
    String inputString,
  ) {
    // start by fresh
    _values.clear();

    inputString = inputString.trim();

    final List<String> lines = getLinesOfText(
      inputString,
      includeEmptyLines: false,
    );

    if (lines.isEmpty) {
      return; // nothing here
    }

    // are we dealing with friendly 3 column values separated by ';'
    if (countOccurrences(lines.first, ';') >= _threeColumnSeparatorCount) {
      //
      // Date ; Description ; Amount
      //
      final List<String> lines = getLinesOfText(
        inputString,
        includeEmptyLines: false,
      );
      if (lines.isNotEmpty) {
        for (final String line in lines) {
          add(attemptToExtractTriples(line));
        }
      }
    } else {
      //
      // CSV like text but use space as separator ' ', instead of ',' this is necessary because some currency use comma in the Amount value
      //
      final List<List<String>> lines = getLinesFromRawTextWithSeparator(
        inputString,
        ' ',
      );
      if (lines.isNotEmpty) {
        for (final List<String> line in lines) {
          if (line.isNotEmpty) {
            add(attemptToExtractTriples(line.join(';')));
          }
        }
      }
    }
  }

  /// Checks each parsed value against existing transactions for the account.
  static void evaluateExistence({
    required final int accountId,
    required final List<ValuesQuality> values,
    required TransactionExistsCallback transactionExistsCallback,
  }) {
    for (final ValuesQuality vq in values) {
      vq.checkIfExistAlready(
        accountId: accountId,
        transactionExistsCallback: transactionExistsCallback,
      );
    }
  }

  /// Returns the list of amount strings from parsed values.
  List<String> getListOfAmountString() {
    final List<String> list = <String>[];
    for (final ValuesQuality value in _values) {
      list.add(value.amount.valueAsString);
    }
    return list;
  }

  /// Returns the list of date strings from parsed values.
  List<String> getListOfDatesString() {
    final List<String> list = <String>[];
    for (final ValuesQuality value in _values) {
      list.add(value.date.valueAsString);
    }
    return list;
  }

  /// Returns the list of description strings from parsed values.
  List<String> getListOfDescriptionString() {
    final List<String> list = <String>[];
    for (final ValuesQuality value in _values) {
      list.add(value.description.valueAsString);
    }
    return list;
  }

  /// True if no parsed values are present.
  bool get isEmpty => onlyNewTransactions.isEmpty;

  /// True if any parsed values are present.
  bool get isNotEmpty => !isEmpty;

  // ignore: unnecessary_getters_setters
  /// Getter for the internal list of parsed ValuesQuality items.
  // ignore: unnecessary_getters_setters
  List<ValuesQuality> get lines {
    //
    return _values;
  }

  /// Setter for the internal list of parsed ValuesQuality items.
  set lines(List<ValuesQuality> value) {
    //
    _values = value;
  }

  /// Returns only those parsed items that are not already existing transactions.
  List<ValuesQuality> get onlyNewTransactions => _values.where((ValuesQuality item) => !item.exist).toList();
}
