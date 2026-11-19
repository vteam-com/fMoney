import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/widgets/charts/my_line_chart.dart';

/// Paints nothing; stands in for a chart overlay painter.
class _EmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  testWidgets('lineChartOverlay paints inside the default line chart margins', (WidgetTester tester) async {
    final _EmptyPainter painter = _EmptyPainter();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(width: 400, height: 300, child: lineChartOverlay(painter)),
        ),
      ),
    );

    final Padding padding = tester.widget<Padding>(find.byType(Padding));
    expect(padding.padding, const EdgeInsets.only(left: lineChartMarginLeft, bottom: lineChartMarginBottom));
    expect(tester.widget<CustomPaint>(find.byType(CustomPaint)).painter, same(painter));
    expect(
      tester.getSize(find.byType(CustomPaint)),
      const Size(400 - lineChartMarginLeft, 300 - lineChartMarginBottom),
    );
  });

  testWidgets('lineChartPlotArea pads its child like the line chart plot area', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: lineChartPlotArea(const Text('price')),
      ),
    );

    final Padding padding = tester.widget<Padding>(find.byType(Padding));
    expect(padding.padding, const EdgeInsets.only(left: lineChartMarginLeft, bottom: lineChartMarginBottom));
    expect(find.text('price'), findsOneWidget);
  });
}
