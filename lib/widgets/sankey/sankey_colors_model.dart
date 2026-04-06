import 'dart:ui';

const Color _sankeyDarkTextColor = Color(0xFFFFFFFF);
const Color _sankeyDarkIncomeColor = Color(0xFF4B6735);
const Color _sankeyDarkExpenseColor = Color(0xFF813E3E);
const Color _sankeyDarkNetColor = Color(0xFF214F72);
const Color _sankeyLightExpenseColor = Color(0xFFC08282);
const Color _sankeyLightIncomeColor = Color(0xFF8BA16A);
const Color _sankeyLightNetColor = Color(0xFF869AAD);
const Color _sankeyLightTextColor = Color(0xFF000000);

/// Represents sankey colors.
class SankeyColors {
  SankeyColors({required bool darkTheme}) {
    if (darkTheme) {
      textColor = _sankeyDarkTextColor;

      colorIncome = _sankeyDarkIncomeColor;
      colorExpense = _sankeyDarkExpenseColor;
      colorNet = _sankeyDarkNetColor;
    }
  }

  Color colorExpense = _sankeyLightExpenseColor;
  Color colorIncome = _sankeyLightIncomeColor;
  Color colorNet = _sankeyLightNetColor;
  // default light theme color
  Color textColor = _sankeyLightTextColor;
}
