import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/widgets/pure/icon_button.dart';

void main() {
  testWidgets('MyIconButton shows the tooltip it is given', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyIconButton(icon: Icons.delete, onPressed: () {}, tooltip: 'Delete'),
        ),
      ),
    );

    expect(find.byTooltip('Delete'), findsOneWidget);
  });

  testWidgets('MyIconButton has no tooltip when none is given', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyIconButton(icon: Icons.delete, onPressed: () {}),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);
  });
}
