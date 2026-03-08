import 'package:flutter/material.dart';
import 'package:money/data/models/field_type.dart';
import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/footer_widgets.dart';

const int _sampleLimit = 10;

/// Represents footer accumulators.
class FooterAccumulators {
  final AccumulatorDateRange<Field<dynamic>> accumulatorDateRange = AccumulatorDateRange<Field<dynamic>>();
  final AccumulatorRange<Field<dynamic>> accumulatorNumericRange = AccumulatorRange<Field<dynamic>>();
  final AccumulatorAverage<Field<dynamic>> accumulatorForAverage = AccumulatorAverage<Field<dynamic>>();
  final AccumulatorList<Field<dynamic>, String> accumulatorListOfText = AccumulatorList<Field<dynamic>, String>();
  final AccumulatorSum<Field<dynamic>, double> accumulatorSumAmount = AccumulatorSum<Field<dynamic>, double>();
  final AccumulatorSum<Field<dynamic>, double> accumulatorSumNumber = AccumulatorSum<Field<dynamic>, double>();

  /// Allowed  to be overridden by derived class
  /// Use the field FooterType to decide how to render the bottom button of each columns
  Widget buildWidget(final Field<dynamic> field) {
    switch (field.footer) {
      case FooterType.range:
        if (field.type == FieldType.date) {
          if (accumulatorDateRange.containsKey(field)) {
            final DateRange value = accumulatorDateRange.getValue(field)!;
            return getFooterForDateRange(value);
          }
        } else if (field.type == FieldType.numeric ||
            field.type == FieldType.amount ||
            field.type == FieldType.quantity) {
          if (accumulatorNumericRange.containsKey(field)) {
            final RunningAverage range = accumulatorNumericRange.getValue(field)!;
            return getFooterForNumericRange(range, field.type);
          }
        }
      case FooterType.count:
        List<String> list = <String>[];

        if (accumulatorListOfText.containsKey(field)) {
          list = accumulatorListOfText.getList(field);
        } else {
          if (accumulatorSumNumber.containsKey(field)) {
            list = accumulatorSumNumber.getValue(field) as List<String>;
          }
        }

        final int count = list.length;
        if (count > 0) {
          String samples = '';
          if (count > _sampleLimit) {
            samples = '${list.take(_sampleLimit).join('\n')}\n...';
          } else {
            samples = list.join('\n');
          }
          return Tooltip(
            message: '$count items\n$samples',
            child: getFooterForInt(count, applyColorBasedOnValue: false),
          );
        }

      case FooterType.sum:
        Widget? widget;
        if (accumulatorSumAmount.containsKey(field)) {
          widget = getFooterForAmount(
            accumulatorSumAmount.getValue(field) as double,
          );
        } else {
          if (accumulatorSumNumber.containsKey(field)) {
            widget = getFooterForInt(
              accumulatorSumNumber.getValue(field) as num,
            );
          }
        }
        return Tooltip(message: 'Sum.', child: widget);

      case FooterType.average:
        if (accumulatorForAverage.containsKey(field)) {
          final RunningAverage range = accumulatorForAverage.getValue(field)!;
          final double value = range.getAverage();
          final Widget widget = field.type == FieldType.amount
              ? getFooterForAmount(value, prefix: 'Av ')
              : getFooterForInt(value, prefix: 'Av ');
          return Tooltip(
            message: field.type == FieldType.amount ? range.descriptionAsMoney : range.descriptionAsInt,
            child: widget,
          );
        }

      case FooterType.none:
      default:
        return const SizedBox();
    }
    return const SizedBox();
  }

  /// Clears all accumulated footer values.
  void clear() {
    accumulatorSumAmount.clear();
    accumulatorSumNumber.clear();
    accumulatorForAverage.clear();
    accumulatorNumericRange.clear();
    accumulatorDateRange.clear();
    accumulatorListOfText.clear();
  }
}
