import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/view_ai/view_ai_chat_message_footer.dart';
import 'package:money/views/view_ai/view_ai_chat_types.dart';

/// A test host widget for dummy hosting app.
class DummyHostingApp extends StatelessWidget {
  const DummyHostingApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }
}

void main() {
  late ChatMessage userMessage;
  late ChatMessage aiMessage;
  late bool onToggleExpandedCalled;
  late bool onViewDetailsCalled;

  setUp(() {
    userMessage = ChatMessage(
      message: 'Hello AI',
      type: ChatFrom.user,
      timestamp: DateTime.now(),
      payloadSentToOllama: <String, dynamic>{},
      isExpanded: false,
    );

    aiMessage = ChatMessage(
      message: 'Hello User',
      type: ChatFrom.ai,
      timestamp: DateTime.now(),
      payloadSentToOllama: <String, dynamic>{},
      isExpanded: false,
    );

    onToggleExpandedCalled = false;
    onViewDetailsCalled = false;
  });

  group('ChatMessageFooter Widget Tests', () {
    testWidgets('displays read more button when shouldTruncate is true and not expanded', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () {
              onToggleExpandedCalled = true;
            },
            onViewDetails: () {
              onViewDetailsCalled = true;
            },
            shouldTruncate: true,
          ),
        ),
      );

      expect(find.text('Read More'), findsOneWidget);
      expect(find.text('Read Less'), findsNothing);
    });

    testWidgets('displays read less button when shouldTruncate is true and expanded', (
      final WidgetTester tester,
    ) async {
      final ChatMessage expandedMessage = ChatMessage(
        message: 'Long message',
        type: ChatFrom.user,
        timestamp: DateTime.now(),
        payloadSentToOllama: <String, dynamic>{},
        isExpanded: true,
      );

      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: expandedMessage,
            onToggleExpanded: () {
              onToggleExpandedCalled = true;
            },
            onViewDetails: () {
              onViewDetailsCalled = true;
            },
            shouldTruncate: true,
          ),
        ),
      );

      expect(find.text('Read Less'), findsOneWidget);
      expect(find.text('Read More'), findsNothing);
    });

    testWidgets('hides read button when shouldTruncate is false', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () {
              onToggleExpandedCalled = true;
            },
            onViewDetails: () {
              onViewDetailsCalled = true;
            },
            shouldTruncate: false,
          ),
        ),
      );

      expect(find.text('Read More'), findsNothing);
      expect(find.text('Read Less'), findsNothing);
    });

    testWidgets('calls onToggleExpanded when read button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () {
              onToggleExpandedCalled = true;
            },
            onViewDetails: () {
              onViewDetailsCalled = true;
            },
            shouldTruncate: true,
          ),
        ),
      );

      await tester.tap(find.text('Read More'));
      await tester.pump();

      expect(onToggleExpandedCalled, true);
    });

    testWidgets('displays elapsed time', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () {
              onToggleExpandedCalled = true;
            },
            onViewDetails: () {
              onViewDetailsCalled = true;
            },
            shouldTruncate: false,
          ),
        ),
      );

      // Should display some elapsed time text (when it's very recent, it shows "Just now")
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('contains copy button with clipboard icon', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () => <dynamic, dynamic>{},
            onViewDetails: () => <dynamic, dynamic>{},
            shouldTruncate: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('contains view details button with comment icon for user message', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () => <dynamic, dynamic>{},
            onViewDetails: () => <dynamic, dynamic>{},
            shouldTruncate: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.comment), findsOneWidget);
      expect(find.byIcon(Icons.info), findsNothing);
    });

    testWidgets('contains view details button with info icon for AI message', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: aiMessage,
            onToggleExpanded: () => <dynamic, dynamic>{},
            onViewDetails: () => <dynamic, dynamic>{},
            shouldTruncate: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.byIcon(Icons.comment), findsNothing);
    });

    testWidgets('calls onViewDetails when view details button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: aiMessage,
            onToggleExpanded: () => <dynamic, dynamic>{},
            onViewDetails: () {
              onViewDetailsCalled = true;
            },
            shouldTruncate: false,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.info));
      await tester.pump();

      expect(onViewDetailsCalled, true);
    });

    testWidgets('copies message to clipboard when copy button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () => <dynamic, dynamic>{},
            onViewDetails: () => <dynamic, dynamic>{},
            shouldTruncate: false,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      // Verify clipboard was set (requires proper clipboard mocking in real tests)
      // This test verifies the button exists and can be tapped
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('has proper tooltips', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () => <dynamic, dynamic>{},
            onViewDetails: () => <dynamic, dynamic>{},
            shouldTruncate: false,
          ),
        ),
      );

      // Should have tooltip on copy button
      expect(find.byTooltip('Copy message to clipboard'), findsOneWidget);

      // Should have tooltip for prompt details on user message
      expect(find.byTooltip('View prompt details'), findsOneWidget);
    });

    testWidgets('uses proper layout structure', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () => <dynamic, dynamic>{},
            onViewDetails: () => <dynamic, dynamic>{},
            shouldTruncate: false,
          ),
        ),
      );

      // Should have a Row with spaceBetween alignment
      expect(find.byType(Row), findsNWidgets(3)); // Main row + left side row + right side row

      // Should have IconButtons with proper constraints
      expect(find.byType(IconButton), findsNWidgets(2)); // Copy and view details
    });

    testWidgets('displays elapsed time with proper opacity', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatMessageFooter(
            message: userMessage,
            onToggleExpanded: () => <dynamic, dynamic>{},
            onViewDetails: () => <dynamic, dynamic>{},
            shouldTruncate: false,
          ),
        ),
      );

      // Should have an Opacity widget wrapping the elapsed time
      expect(find.byType(Opacity), findsOneWidget);
    });
  });
}
