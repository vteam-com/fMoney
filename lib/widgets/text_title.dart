import 'package:money/helpers/color_helper.dart';

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
