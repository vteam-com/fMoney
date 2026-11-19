import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';
import 'package:money/widgets/pure/icon_button.dart';
import 'package:money/widgets/pure/my_text_input_widget.dart';

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

  /// Releases the text controller owned by this state.
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Shows a date the owner changed from outside; an owner echoing the date being typed (even
  /// formatted differently) leaves the text box alone.
  @override
  void didUpdateWidget(PickerEditBoxDate oldWidget) {
    super.didUpdateWidget(oldWidget);
    showOwnerValueChange(
      _textController,
      oldWidget.initialValue,
      widget.initialValue,
      isSameValue: (String text, String value) => attemptToGetDateFromText(text) == attemptToGetDateFromText(value),
    );
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
            onChanged: (String value) {
              setState(() {
                widget.onChanged(value);
              });
            },
          ),
        ),
        MyIconButton(
          onPressed: () async {
            final DateTime dateSelected = attemptToGetDateFromText(_textController.text) ?? DateTime.now();
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
