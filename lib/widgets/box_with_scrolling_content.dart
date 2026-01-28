import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/box.dart';

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
    width: 300,
    height: height,
    // height: 300,
    margin: 10,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}
