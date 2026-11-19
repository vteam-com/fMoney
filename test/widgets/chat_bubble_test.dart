import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/widgets/components/chat_bubble_widget.dart';
import 'package:money/widgets/components/processing_indicator_widget.dart';

/// Returns the corners of the only bubble on screen.
BorderRadius _bubbleCorners(WidgetTester tester) {
  final Container bubble = tester.widget<Container>(
    find.descendant(of: find.byType(ChatBubble), matching: find.byType(Container)),
  );
  return (bubble.decoration! as BoxDecoration).borderRadius! as BorderRadius;
}

void main() {
  testWidgets('a user bubble has its tail on the bottom-right corner', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatBubble(color: Colors.blue, isFromUser: true, child: Text('hi')),
      ),
    );

    final BorderRadius corners = _bubbleCorners(tester);
    expect(corners.bottomRight.x, lessThan(corners.bottomLeft.x));
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('the thinking indicator uses the same bubble as other messages, tail on the left', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProcessingIndicator())));

    final BorderRadius corners = _bubbleCorners(tester);
    expect(corners.bottomLeft.x, lessThan(corners.bottomRight.x));
  });
}
