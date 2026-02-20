import 'package:flutter/material.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/widgets/default_values.dart';
import 'package:money/widgets/pure/icon_button.dart';
import 'package:money/widgets/pure/my_text_input.dart';

const int _minDateYear = 1950;

/// A stateful widget for picker edit box date.
class PickerEditBoxDate extends StatefulWidget {
  const PickerEditBoxDate({
    required this.onChanged,
    super.key,
    this.initialValue,
  });

  final String? initialValue;
  final void Function(String) onChanged;

  @override
  PickerEditBoxDateState createState() => PickerEditBoxDateState();
}

/// State for picker edit box date.
class PickerEditBoxDateState extends State<PickerEditBoxDate> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialValue ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: MyTextInput(
            controller: _textController,
            border: false,
            onChanged: (final String value) {
              setState(() {
                widget.onChanged(value);
              });
            },
          ),
        ),
        MyIconButton(
          onPressed: () async {
            final DateTime dateSelected = valueOrDefaultDate(
              attemptToGetDateFromText(widget.initialValue ?? ''),
              defaultValueIfNull: DateTime.now(),
            );
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: dateSelected,
              firstDate: DateTime(_minDateYear),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              _textController.text = dateToString(pickedDate);
              widget.onChanged(_textController.text);
            }
          },
          icon: Icons.edit_calendar,
        ),
      ],
    );
  }
}
