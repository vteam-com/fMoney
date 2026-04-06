// ignore: fcheck_dead_code
import 'package:flutter/material.dart';
import 'package:money/data/models/ranges_model.dart';

/// Represents chart event.
class ChartEvent {
  ChartEvent({
    required this.dates,
    required this.amount,
    required this.quantity,
    required this.description,
    required this.colorBasedOnQuantity,
    this.color,
  });

  final double amount;
  final Color? color;
  final bool colorBasedOnQuantity;
  final DateRange dates;
  final String description;
  final double quantity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ChartEvent) {
      return false;
    }

    return dates == other.dates &&
        amount == other.amount &&
        quantity == other.quantity &&
        description == other.description;
  }

  @override
  int get hashCode => Object.hash(dates, amount, quantity, description);

  /// Returns the display color based on buy/sell or amount sign.
  Color get colorToUse {
    if (this.color == null) {
      return colorBasedOnQuantity
          ? (quantity == 0 ? Colors.grey : (isBuy ? Colors.orange : Colors.blue))
          : (amount == 0 ? Colors.grey : (amount.isNegative ? Colors.orange : Colors.blue));
    }
    return this.color!;
  }

  /// True if this event represents a buy (positive quantity).
  bool get isBuy => quantity > 0;

  /// True if this event represents a sell (negative quantity).
  bool get isSell => quantity < 0;
}
