import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/pickers/color_picker.dart';
import 'package:money/widgets/pure/circle_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/my_text_input_widget.dart';

const double _colorSwatchSizeLarge = 40.0;

/// A stateful widget for mutate field color.
class MutateFieldColor extends StatefulWidget {
  const MutateFieldColor({
    required this.colorAsHex,
    required this.onEdited,
    super.key,
  });

  final String colorAsHex;
  final void Function(String) onEdited;

  @override
  State<MutateFieldColor> createState() => _MutateFieldColorState();
}

class _MutateFieldColorState extends State<MutateFieldColor> {
  late TextEditingController controllerForText = TextEditingController(
    text: widget.colorAsHex,
  );

  @override
  Widget build(BuildContext context) {
    late Color color = getColorFromString(controllerForText.text);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: MyTextInput(
            controller: controllerForText,
            onChanged: (String colorText) {
              setState(() {
                color = getColorFromString(colorText);
                widget.onEdited(controllerForText.text);
              });
            },
          ),
        ),
        gapLarge(),
        MyCircle(colorFill: color, colorBorder: Colors.grey, size: _colorSwatchSizeLarge),
        gapLarge(),
        Expanded(
          child: ColorPicker(
            color: color,
            onColorChanged: (Color color) {
              setState(() {
                controllerForText.text = colorToHexString(
                  color,
                  includeAlpha: false,
                );
                widget.onEdited(controllerForText.text);
              });
            },
          ),
        ),
      ],
    );
  }
}
