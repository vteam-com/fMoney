import 'package:money/helpers/color_helper.dart';

Widget buildTitle(BuildContext context, String text) {
  return Text(text, style: getTextTheme(context).headlineSmall);
}

Widget buildWarning(final BuildContext? context, final String text) {
  return Text(
    text,
    style: context == null ? null : getTextTheme(context).bodyMedium!.copyWith(color: Colors.orange),
  );
}
