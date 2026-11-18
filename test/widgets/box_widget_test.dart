import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pure/box_widget.dart';

void main() {
  testWidgets('a titled Box with a margin adds room for the title above the margin', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Box(title: 'Title', margin: 4, child: const SizedBox()),
        ),
      ),
    );

    final Container container = tester.widget<Container>(
      find.descendant(of: find.byType(Box), matching: find.byType(Container)).first,
    );
    expect(container.margin!.resolve(TextDirection.ltr).top, 4 + SizeForPadding.large);
  });
}
