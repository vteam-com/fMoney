import 'dart:math';

import 'package:flutter/material.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/data/entities/category.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/widgets/circle.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _topCategoriesLimit = 3;
const int _zeroInt = 0;
const double _zeroDouble = 0.0;
const double _otherCircleSize = 10.0;
const int _labelFlex = 2;
const double _labelFontSize = 9.0;
const double _positiveMultiplier = 1.0;
const double _negativeMultiplier = -1.0;

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({
    required this.listCategoryNameToAmount,
    required this.asIncome,
    super.key,
  });

  final bool asIncome;

  final List<PairIntDouble> listCategoryNameToAmount;

  @override
  Widget build(BuildContext context) {
    // Sort the data by value in descending order
    listCategoryNameToAmount.sort(
      (PairIntDouble a, PairIntDouble b) => b.value.compareTo(a.value),
    );

    // Extract top 3 values and calculate total value of others
    final int topCategoryToShow = min(_topCategoriesLimit, listCategoryNameToAmount.length);

    final double otherSumValues = listCategoryNameToAmount
        .skip(topCategoryToShow)
        .fold(
          _zeroDouble,
          (double prev, PairIntDouble current) => prev + current.value,
        );

    final List<Widget> bars = <Widget>[];

    for (int top = _zeroInt; top < topCategoryToShow; top++) {
      final Category? category = Data().categories.get(
        listCategoryNameToAmount[top].key,
      );
      if (category != null) {
        bars.add(
          _buildBar(
            category.fieldName.value,
            category.getColorWidget(),
            listCategoryNameToAmount[top].value,
          ),
        );
      }
    }

    if (otherSumValues > _zeroDouble) {
      bars.add(
        _buildBar(
          'Others',
          const MyCircle(colorFill: Colors.grey, size: _otherCircleSize),
          otherSumValues,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bars,
    );
  }

  Widget _buildBar(String label, Widget colorWidget, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: _labelFlex,
          child: Text(
            label,
            style: const TextStyle(fontSize: _labelFontSize),
            textAlign: TextAlign.justify,
            textWidthBasis: TextWidthBasis.longestLine,
            softWrap: false,
          ),
        ),
        colorWidget,
        Expanded(
          child: WidgetFromData(
            amountModel: AmountModel(amount: value * (asIncome ? _positiveMultiplier : _negativeMultiplier)),
          ),
        ),
      ],
    );
  }
}
