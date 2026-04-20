import 'package:flutter/widgets.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';

/// Displays a [DateTime] as a formatted text label using monospace font.
class DisplayDate extends StatelessWidget {
  const DisplayDate({
    super.key,
    this.date,
    this.align = TextAlign.left,
  });
  final TextAlign? align;
  final DateTime? date;
  @override
  Widget build(BuildContext context) {
    return Text(
      dateToString(date),
      textAlign: align,
      overflow: TextOverflow.ellipsis, // Clip with ellipsis
      maxLines: 1, // Restrict to single line,
      style: const TextStyle(fontFamily: SharedStrings.fontRobotoMono),
    );
  }
}
