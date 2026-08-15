import 'package:flutter/foundation.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Width of the drag-handle zone between resizable columns, in logical pixels.
const double columnResizeHandleWidth = 6;

/// Minimum pixel width for any single resizable column.
const double minimumColumnWidth = 64;

/// Shared mutable column-width ratios for synchronized header and body resizing.
///
/// The list length equals the number of visible (non-hidden) columns; each
/// entry is a fraction in [0, 1] and all entries sum to 1.
class ColumnWidthsNotifier extends ValueNotifier<List<double>> {
  /// Creates a notifier with the given initial width ratios.
  // ignore: use_super_parameters
  ColumnWidthsNotifier(List<double> value) : super(value);

  /// Builds initial ratios from field column-width metadata, visible fields only.
  ///
  /// Hidden fields (i.e. [ColumnWidth.hidden]) are excluded. The resulting
  /// ratios are proportional to each field's [ColumnWidth.index] value.
  static ColumnWidthsNotifier fromFields(FieldDefinitions fields) {
    final List<double> weights = <double>[];
    for (final Field<dynamic> field in fields) {
      if (field.columnWidth != ColumnWidth.hidden) {
        weights.add(field.columnWidth.index.toDouble());
      }
    }
    if (weights.isEmpty) {
      return ColumnWidthsNotifier(<double>[]);
    }
    final double sum = weights.fold(0.0, (double s, double v) => s + v);
    final List<double> ratios = sum > 0
        ? weights.map((double w) => w / sum).toList()
        : List<double>.filled(weights.length, 1.0 / weights.length);
    return ColumnWidthsNotifier(ratios);
  }

  /// Adjusts two adjacent visible columns at [leftIndex] by [deltaRatio].
  ///
  /// The combined ratio of the two columns is preserved. [minRatio] enforces a
  /// minimum share for either column to prevent total collapse.
  void resizeAtBoundary(
    int leftIndex,
    double deltaRatio,
    double minRatio,
  ) {
    if (leftIndex < 0 || leftIndex >= value.length - 1) {
      return;
    }
    final List<double> updated = List<double>.from(value);
    final double combined = updated[leftIndex] + updated[leftIndex + 1];
    if (combined < minRatio + minRatio) {
      return;
    }
    final double newLeft = (updated[leftIndex] + deltaRatio).clamp(minRatio, combined - minRatio);
    updated[leftIndex] = newLeft;
    updated[leftIndex + 1] = combined - newLeft;
    value = updated;
  }
}
