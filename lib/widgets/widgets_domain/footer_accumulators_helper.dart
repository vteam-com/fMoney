import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/accumulator_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/widgets_domain/footer_widgets_helper.dart';

const int _sampleLimit = 10;

/// Represents footer accumulators.
class FooterAccumulators {
  final AccumulatorDateRange<Field<dynamic>> accumulatorDateRange = AccumulatorDateRange<Field<dynamic>>();
  final AccumulatorAverage<Field<dynamic>> accumulatorNumericRange = AccumulatorAverage<Field<dynamic>>();
  final AccumulatorAverage<Field<dynamic>> accumulatorForAverage = AccumulatorAverage<Field<dynamic>>();
  final AccumulatorList<Field<dynamic>, String> accumulatorListOfText = AccumulatorList<Field<dynamic>, String>();
  final AccumulatorSum<Field<dynamic>, double> accumulatorSumAmount = AccumulatorSum<Field<dynamic>, double>();
  final AccumulatorSum<Field<dynamic>, double> accumulatorSumNumber = AccumulatorSum<Field<dynamic>, double>();

  /// List instance the accumulators were last computed for by [recomputeIfChanged].
  List<DataObject>? _computedForItems;

  /// Data-version stamp the accumulators were last computed for by [recomputeIfChanged].
  String _computedForVersion = '';

  /// ISO 4217 code shared by every amount of each amount column; the default currency once a column mixes currencies.
  final Map<Field<dynamic>, String> _currencyOfAmountColumn = <Field<dynamic>, String>{};

  /// Allowed  to be overridden by derived class
  /// Use the field FooterType to decide how to render the bottom button of each columns
  Widget buildWidget(Field<dynamic> field) {
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
            return getFooterForNumericRange(range, field.type, iso4217code: _currencyOf(field));
          }
        }
      case FooterType.count:
        // Count footers only ever accumulate text: numeric columns with a count footer store their values as text.
        final List<String> list = accumulatorListOfText.containsKey(field)
            ? accumulatorListOfText.getList(field)
            : <String>[];

        final int count = list.length;
        if (count > 0) {
          String samples = '';
          if (count > _sampleLimit) {
            samples = '${list.take(_sampleLimit).join(SharedStrings.lineFeed)}${SharedStrings.footerSampleTruncation}';
          } else {
            samples = list.join(SharedStrings.lineFeed);
          }
          final String countLabel = AppL10n.tr(
            AppTranslationKeys.entriesCount,
            params: <String, String>{'count': count.toString()},
          );
          return Tooltip(
            message: '$countLabel${SharedStrings.lineFeed}$samples',
            child: getFooterForInt(count, applyColorBasedOnValue: false),
          );
        }

      case FooterType.sum:
        Widget? widget;
        if (accumulatorSumAmount.containsKey(field)) {
          widget = getFooterForAmount(
            accumulatorSumAmount.getValue(field) as double,
            iso4217code: _currencyOf(field),
          );
        } else {
          if (accumulatorSumNumber.containsKey(field)) {
            widget = getFooterForInt(
              accumulatorSumNumber.getValue(field) as num,
            );
          }
        }
        return Tooltip(
          message: SharedStrings.footerSumLabel,
          child: widget,
        );

      case FooterType.average:
        if (accumulatorForAverage.containsKey(field)) {
          final RunningAverage range = accumulatorForAverage.getValue(field)!;
          final double value = range.getAverage();
          final String averagePrefix = AppL10n.tr(AppTranslationKeys.avgLabel);
          final Widget widget = field.type == FieldType.amount
              ? getFooterForAmount(value, prefix: averagePrefix, iso4217code: _currencyOf(field))
              : getFooterForInt(value, prefix: averagePrefix);
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
    _currencyOfAmountColumn.clear();
  }

  /// Clears and recomputes all footer accumulators from [items] using the
  /// field [definitions].
  void recompute({
    required List<DataObject> items,
    required FieldDefinitions definitions,
  }) {
    clear();

    for (final DataObject item in items) {
      for (final Field<dynamic> field in definitions) {
        switch (field.type) {
          case FieldType.text:
            accumulatorListOfText.cumulate(
              field,
              field.getValueForDisplay(item).toString(),
            );

          case FieldType.date:
            final dynamic dateTime = field.getValueForDisplay(item);
            if (dateTime != null) {
              accumulatorDateRange.cumulate(
                field,
                dateTime as DateTime,
              );
            }
          case FieldType.dateRange:
            final dynamic dateRangeValue = field.getValue(item);
            if (dateRangeValue.min != null) {
              accumulatorDateRange.cumulate(
                field,
                dateRangeValue.min as DateTime,
              );
            }
            if (dateRangeValue.max != null) {
              accumulatorDateRange.cumulate(
                field,
                dateRangeValue.max as DateTime,
              );
            }

          case FieldType.widget:
            accumulatorListOfText.cumulate(field, field.getReadableValue(item));

          case FieldType.amount:
            final dynamic displayValue = field.getValueForDisplay(item);
            final double value = smartToDouble(displayValue);
            if (isNumber(value)) {
              _cumulateCurrency(
                field,
                displayValue is AmountModel ? displayValue.iso4217 : Constants.defaultCurrency,
              );
              accumulatorSumAmount.cumulate(field, value);
              if (field.footer == FooterType.average) {
                accumulatorForAverage.cumulate(
                  field,
                  value,
                );
              }
              if (field.footer == FooterType.range) {
                accumulatorNumericRange.cumulate(
                  field,
                  value,
                );
              }
            }

          case FieldType.numeric:
          case FieldType.amountShorthand:
          case FieldType.numericShorthand:
          case FieldType.quantity:
            final dynamic value = field.getValueForDisplay(item);
            if (field.footer == FooterType.count) {
              accumulatorListOfText.cumulate(
                field,
                getIntAsText(value as int),
              );
            } else {
              if (value is num) {
                accumulatorSumNumber.cumulate(
                  field,
                  value.toDouble(),
                );
                if (field.footer == FooterType.average) {
                  accumulatorForAverage.cumulate(
                    field,
                    value,
                  );
                }
                if (field.footer == FooterType.range) {
                  accumulatorNumericRange.cumulate(
                    field,
                    value,
                  );
                }
              }
            }
          case FieldType.percentage:
          case FieldType.toggle:
            break;
        }
      }
    }
  }

  /// Recomputes from [items] only when the list instance or the data [version] stamp changed since the last call.
  ///
  /// Unrelated rebuilds such as selection changes then skip the full re-scan;
  /// pass a [version] that changes on every data edit when [items] can be
  /// edited in place.
  void recomputeIfChanged({
    required List<DataObject> items,
    required FieldDefinitions definitions,
    String version = '',
  }) {
    if (identical(items, _computedForItems) && version == _computedForVersion) {
      return;
    }
    _computedForItems = items;
    _computedForVersion = version;
    recompute(items: items, definitions: definitions);
  }

  /// Records that [field] holds an amount in [iso4217]; a column mixing currencies falls back to the default currency.
  void _cumulateCurrency(Field<dynamic> field, String iso4217) {
    final String? known = _currencyOfAmountColumn[field];
    _currencyOfAmountColumn[field] = known == null || known == iso4217 ? iso4217 : Constants.defaultCurrency;
  }

  /// Returns the ISO 4217 code to format [field]'s footer amounts with.
  String _currencyOf(Field<dynamic> field) => _currencyOfAmountColumn[field] ?? Constants.defaultCurrency;
}
