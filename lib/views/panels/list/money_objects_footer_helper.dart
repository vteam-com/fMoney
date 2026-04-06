import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/default_values_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
import 'package:money/widgets/widgets_domain/footer_accumulators_helper.dart';

/// Recomputes footer accumulators for [items] using [definitions].
void recomputeFooterAccumulators({
  required FooterAccumulators footerAccumulators,
  required List<DataObject> items,
  required FieldDefinitions definitions,
}) {
  footerAccumulators.clear();

  for (final DataObject item in items) {
    for (final Field<dynamic> field in definitions) {
      switch (field.type) {
        case FieldType.text:
          footerAccumulators.accumulatorListOfText.cumulate(
            field,
            field.getValueForDisplay(item).toString(),
          );

        case FieldType.date:
          final dynamic dateTime = field.getValueForDisplay(item);
          if (dateTime != null) {
            footerAccumulators.accumulatorDateRange.cumulate(
              field,
              dateTime as DateTime,
            );
          }
        case FieldType.dateRange:
          final dynamic dateRangeValue = field.getValue(item);
          if (dateRangeValue.min != null) {
            footerAccumulators.accumulatorDateRange.cumulate(
              field,
              dateRangeValue.min as DateTime,
            );
          }
          if (dateRangeValue.max != null) {
            footerAccumulators.accumulatorDateRange.cumulate(
              field,
              dateRangeValue.max as DateTime,
            );
          }

        case FieldType.widget:
          if (field.getValueForReading != null) {
            footerAccumulators.accumulatorListOfText.cumulate(
              field,
              field.getValueForReading?.call(item)!.toString() ?? '',
            );
          }

        case FieldType.amount:
          final double value = smartToDouble(field.getValueForDisplay(item));
          if (isNumber(value)) {
            footerAccumulators.accumulatorSumAmount.cumulate(field, value);
            if (field.footer == FooterType.average) {
              footerAccumulators.accumulatorForAverage.cumulate(
                field,
                value,
              );
            }
            if (field.footer == FooterType.range) {
              footerAccumulators.accumulatorNumericRange.cumulate(
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
            footerAccumulators.accumulatorListOfText.cumulate(
              field,
              getIntAsText(value as int),
            );
          } else {
            if (value is num) {
              footerAccumulators.accumulatorSumNumber.cumulate(
                field,
                value.toDouble(),
              );
              if (field.footer == FooterType.average) {
                footerAccumulators.accumulatorForAverage.cumulate(
                  field,
                  value,
                );
              }
              if (field.footer == FooterType.range) {
                footerAccumulators.accumulatorNumericRange.cumulate(
                  field,
                  value,
                );
              }
            }
          }
        default:
          break;
      }
    }
  }
}
