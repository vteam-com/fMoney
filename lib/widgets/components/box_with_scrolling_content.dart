import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/pure/box.dart';

const double _boxWidth = 300;
const double _boxMargin = 10;

/// A stateless widget for box with scrolling content.
class BoxWithScrollingContent extends StatelessWidget {
  const BoxWithScrollingContent({
    super.key,
    required this.children,
    this.height,
  });

  final List<Widget> children;
  final double? height;

  @override
  Widget build(final BuildContext context) => Box(
    color: getColorTheme(context).surface,
    width: _boxWidth,
    height: height,
    // height: 300,
    margin: _boxMargin,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}
