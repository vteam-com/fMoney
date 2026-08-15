import 'package:flutter/widgets.dart';

const double _gapSmall = 5;
const double _gapMedium = 8;
const double _gapLarge = 21;
const double _gapHuge = 55;

/// Returns a SizedBox square of the given [size].
Widget gap(double size) {
  return SizedBox(width: size, height: size);
}

/// Returns a small gap widget.
Widget gapSmall() {
  return gap(_gapSmall);
}

/// Returns a medium gap widget.
Widget gapMedium() {
  return gap(_gapMedium);
}

/// Returns a large gap widget.
Widget gapLarge() {
  return gap(_gapLarge);
}

/// Returns a huge gap widget.
Widget gapHuge() {
  return gap(_gapHuge);
}
