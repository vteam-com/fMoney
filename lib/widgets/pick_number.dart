import 'package:flutter/material.dart';
import 'package:money/widgets/gaps.dart';

class NumberPicker extends StatelessWidget {
  NumberPicker({
    super.key,
    required this.title,
    required int selectedNumber,
    required this.onChanged,
    this.minValue = 1,
    this.maxValue = 10,
  }) : selectedNumber = selectedNumber.clamp(minValue, maxValue);

  final int maxValue;
  final int minValue;
  final void Function(int) onChanged;
  final int selectedNumber;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
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
                  maxValue - minValue + 1,
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
