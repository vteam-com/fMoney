import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/widgets/charts/chart_widget.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';

/// A theme palette whose colors differ from the built-in fallback.
const MoneyThemeData _palette = MoneyThemeData(
  success: Colors.teal,
  warning: Colors.amber,
  error: Colors.purple,
  disabled: Colors.brown,
  quantityPositive: Colors.blue,
  quantityNegative: Colors.orange,
  info: Colors.cyan,
);

void main() {
  test('a value within the zero tolerance gets the zero color', () {
    expect(_palette.colorBasedOnValue(0.0000001), _palette.disabled);
    expect(_palette.colorBasedOnValue(-0.0000001), _palette.disabled);
    expect(_palette.colorBasedOnValue(2), _palette.success);
    expect(_palette.colorBasedOnValue(-2), _palette.error);
  });

  testWidgets('bar chart rods use the theme colors for gains and losses', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[_palette]),
        home: Scaffold(
          body: Chart(list: <PairXYY>[PairXYY('gain', 100), PairXYY('loss', -50)]),
        ),
      ),
    );

    final List<BarChartGroupData> groups = tester.widget<BarChart>(find.byType(BarChart)).data.barGroups;
    expect(groups.map((BarChartGroupData group) => group.barRods.first.color), <Color>[
      _palette.success,
      _palette.error,
    ]);
  });
}
