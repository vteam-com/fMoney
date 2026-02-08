import 'package:flutter/widgets.dart';

const double _gapSmall = 5;
const double _gapMedium = 8;
const double _gapLarge = 21;
const double _gapHuge = 55;

Widget gap(final double size) {
  return SizedBox(width: size, height: size);
}

Widget gapSmall() {
  return gap(_gapSmall);
}

Widget gapMedium() {
  return gap(_gapMedium);
}

Widget gapLarge() {
  return gap(_gapLarge);
}

Widget gapHuge() {
  return gap(_gapHuge);
}
