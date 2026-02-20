import 'package:money/helpers/color_helper.dart';

/// A stateless widget for text title.
class TextTitle extends StatelessWidget {
  const TextTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      title,
      style: getTextTheme(
        context,
      ).headlineSmall!.copyWith(color: getColorTheme(context).onSurface),
    );
  }
}
