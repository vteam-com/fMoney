// igno. re: fcheck_dead_code
import 'package:money/helpers/color_helper.dart';

/// Builds an orange warning-styled Text widget.
Widget buildWarning(BuildContext? context, String text) {
  return Text(
    text,
    style: context == null ? null : getTextTheme(context).bodyMedium!.copyWith(color: Colors.orange),
  );
}
