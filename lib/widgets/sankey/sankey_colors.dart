import 'dart:ui';

class SankeyColors {
  SankeyColors({required bool darkTheme}) {
    if (darkTheme) {
      textColor = const Color(0xffffffff);

      colorIncome = const Color(0xff4b6735);
      colorExpense = const Color(0xff813e3e);
      colorNet = const Color(0xff214f72);
    }
  }

  Color colorExpense = const Color(0xffC08282);
  Color colorIncome = const Color(0xff8ba16a);
  Color colorNet = const Color(0xff869AAD);
  // default light theme color
  Color textColor = const Color(0xff000000);
}
