import 'package:flutter/material.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

const int _defaultMinValue = 1;
const int _defaultMaxValue = 10;
const int _inclusiveRangeOffset = 1;
const double _pickerHeight = 40;

/// A stateless widget for number picker.
class NumberPicker extends StatelessWidget {
  NumberPicker({
    super.key,
    required this.title,
    required int selectedNumber,
    required this.onChanged,
    this.minValue = _defaultMinValue,
    this.maxValue = _defaultMaxValue,
  }) : selectedNumber = selectedNumber.clamp(minValue, maxValue);

  final int maxValue;
  final int minValue;
  final void Function(int) onChanged;
  final int selectedNumber;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _pickerHeight,
      child: IntrinsicWidth(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text('$title:'),
            gapSmall(),
            Expanded(
              child: DropdownButton<int>(
                value: selectedNumber,
                items: List<DropdownMenuItem<int>>.generate(
                  maxValue - minValue + _inclusiveRangeOffset,
                  (int index) => DropdownMenuItem<int>(
                    value: index + minValue,
                    child: Text('${index + minValue}'),
                  ),
                ),
                onChanged: (int? value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
