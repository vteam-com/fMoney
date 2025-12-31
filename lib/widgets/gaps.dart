import 'package:flutter/widgets.dart';

// Exports
export 'package:flutter/widgets.dart';

Widget gap(final double size) {
  return SizedBox(width: size, height: size);
}

Widget gapSmall() {
  return gap(5);
}

Widget gapMedium() {
  return gap(8);
}

Widget gapLarge() {
  return gap(21);
}

Widget gapHuge() {
  return gap(55);
}
