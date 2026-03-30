import 'package:money/helpers/color_helper.dart';

const double _pickerButtonWidth = 30.0;
const double _pickerButtonHeight = 22.0;
const double _pickerLetterFontSize = 10.0;

/// A stateful widget for picker letters.
class PickerLetters extends StatefulWidget {
  const PickerLetters({
    required this.options,
    required this.onSelected,
    super.key,
    this.selected,
    this.vertical = true,
  });

  final void Function(String selectedValue) onSelected;
  final List<String> options;
  final String? selected;
  final bool vertical;

  @override
  State<PickerLetters> createState() => _PickerLettersState();
}

class _PickerLettersState extends State<PickerLetters> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[];

    for (final String option in widget.options) {
      final String letter = option.isEmpty ? ' ' : option[0];
      final bool isSelected = widget.selected == letter;
      final ColorScheme theme = getColorTheme(context);
      buttons.add(
        TextButton(
          onPressed: () {
            if (isSelected) {
              // already select, so unselected
              widget.onSelected('');
            } else {
              widget.onSelected(letter);
            }
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            // Remove padding
            minimumSize: const Size(_pickerButtonWidth, _pickerButtonHeight),
            maximumSize: const Size(_pickerButtonWidth, _pickerButtonHeight),
            foregroundColor: isSelected ? theme.onPrimary : theme.onSurface,
            backgroundColor: isSelected ? theme.primary : theme.surface,
          ),
          child: Text(letter, style: const TextStyle(fontSize: _pickerLetterFontSize)),
        ),
      );
    }

    if (widget.vertical) {
      return Column(children: buttons);
    } else {
      return Row(children: buttons);
    }
  }
}
