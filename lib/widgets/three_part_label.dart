import 'package:money/helpers/color_helper.dart';

const double _iconSlotWidth = 40;
const double _textSpacing = 20;

/// A stateless widget for three part label.
class ThreePartLabel extends StatelessWidget {
  const ThreePartLabel({
    super.key,
    this.icon,
    this.text1 = '',
    this.text2 = '',
    this.small = false,
    this.isVertical = false,
  });

  final Widget? icon;
  final bool isVertical;
  final bool small;
  final String text1;
  final String text2;

  @override
  Widget build(final BuildContext context) {
    return isVertical
        ? Column(children: <Widget>[renderText1(context), renderText2(context)])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Icon
              SizedBox(width: icon == null ? null : _iconSlotWidth, child: icon),
              // Text1 <space> Text2
              renderText1(context),
              const SizedBox(width: _textSpacing),
              renderText2(context),
            ],
          );
  }

  /// Renders the first text block with size-dependent styling.
  Widget renderText1(final BuildContext context) {
    if (small) {
      return Text(text1, style: getTextTheme(context).labelLarge);
    } else {
      return Text(text1, style: getTextTheme(context).titleLarge);
    }
  }

  /// Renders the second text block with bodySmall styling.
  Widget renderText2(final BuildContext context) {
    return Text(text2, style: getTextTheme(context).bodySmall);
  }
}
