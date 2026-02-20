import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/pairs.dart';

const double _maxHue = 359.7;
const double _hueMin = 0;
const double _colorPickerRadius = 8;
const double _colorPickerInnerRadius = 7;
const double _borderAlpha = 0.5;
const double _borderWidth = 1;
const double _sliderHeight = 30;
const int _hueDivisions = 360 * 2;
const double _brightnessMin = 0;
const double _brightnessMax = 1;
const double _brightnessDefault = 0.5;
const int _brightnessDivisions = 100;
const int _brightnessPercentScale = 100;

/// A stateful widget for color picker.
class ColorPicker extends StatefulWidget {
  const ColorPicker({
    required this.color,
    required this.onColorChanged,
    super.key,
  });

  final Color color;
  final void Function(Color) onColorChanged;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  /// From 0.0% to 1.0% 0%=Black 100%=White
  late double brightness;

  /// From 0 to 360
  late double hue;

  @override
  void initState() {
    super.initState();
    fromInputColorToHueAndBrightness();
  }

  @override
  void didUpdateWidget(covariant ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    fromInputColorToHueAndBrightness();
  }

  @override
  Widget build(BuildContext context) {
    if (hue > _maxHue) {
      hue = _maxHue;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_colorPickerRadius),
        border: Border.all(
          color: getColorTheme(context).onSurface.withValues(alpha: _borderAlpha),
          width: _borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          _colorPickerInnerRadius,
        ), // Same radius as container
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: _sliderHeight,
              child: CustomPaint(
                painter: _HueGradientPainter(),
                child: Slider(
                  value: hue,
                  min: _hueMin,
                  max: _maxHue,
                  divisions: _hueDivisions,
                  label: hue.floor().toString(),
                  onChanged: (double value) {
                    setState(() {
                      hue = value;
                      if (brightness == _brightnessMin || brightness == _brightnessMax) {
                        brightness = _brightnessDefault;
                      }
                      widget.onColorChanged(hsvToColor(hue, brightness));
                    });
                  },
                ),
              ),
            ),
            SizedBox(
              height: _sliderHeight,
              child: CustomPaint(
                painter: _BrightnessGradientPainter(hue: hue),
                child: Slider(
                  value: brightness,
                  min: _brightnessMin,
                  max: _brightnessMax,
                  divisions: _brightnessDivisions,
                  label: (brightness * _brightnessPercentScale).round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      brightness = value;
                      widget.onColorChanged(hsvToColor(hue, brightness));
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void fromInputColorToHueAndBrightness() {
    final Pair<double, double> bothValues = getHueAndBrightnessFromColor(
      widget.color,
    );
    hue = bothValues.first;
    brightness = bothValues.second;
  }
}

class _HueGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const List<Color> colors = <Color>[
      Color.fromRGBO(255, 0, 0, 1), // 1 Red
      Color.fromRGBO(255, 255, 0, 1), // 2 Yellow
      Color.fromRGBO(0, 255, 0, 1), // 3 Green

      Color.fromRGBO(0, 255, 255, 1), // 4 Cyan

      Color.fromRGBO(0, 0, 255, 1), // 5 Blue
      Color.fromRGBO(255, 0, 255, 1), // 6 Purple
      Color.fromRGBO(255, 0, 0, 1), // 7 Red
    ];

    final Gradient gradient = LinearGradient(
      colors: colors,
      stops: calculateSpread(0, 1, colors.length),
    );

    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _BrightnessGradientPainter extends CustomPainter {
  _BrightnessGradientPainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Gradient gradient = LinearGradient(
      colors: <Color>[
        HSLColor.fromAHSL(1.0, hue, 1.0, 0.0).toColor(), // Black
        HSLColor.fromAHSL(1.0, hue, 1.0, _brightnessDefault).toColor(), // Middle lightness
        HSLColor.fromAHSL(1.0, hue, 1.0, 1.0).toColor(), // White
      ],
    );

    final Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // We want to repaint when the hue changes
  }
}
