import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/home/ai/ai_header_widget.dart';

/// A test host widget for dummy hosting app.
class DummyHostingApp extends StatelessWidget {
  const DummyHostingApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
  late List<Map<String, dynamic>> mockModels;
  late String selectedModel;
  late int questionCount;
  late int contextTokensCount;
  late bool onModelSelectedCalled;
  late String selectedModelValue;

  setUp(() {
    mockModels = <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'llama3.2:3b',
        'size': 2147483648, // 2GB
      },
      <String, dynamic>{
        'name': 'llama3.2:1b',
        'size': 1073741824, // 1GB
      },
    ];
    selectedModel = 'llama3.2:3b';
    questionCount = 5;
    contextTokensCount = 1500;
    onModelSelectedCalled = false;
    selectedModelValue = '';
  });

  group('ViewAiHeader Widget Tests', () {
    testWidgets('displays AI Assistant title', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      expect(find.text('AI Assistant'), findsOneWidget);
    });

    testWidgets('displays selected model name', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      expect(find.text('llama3.2:3b'), findsOneWidget);
    });

    testWidgets('displays question count and tokens', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      expect(find.text('Questions: 5 | Tokens: 1.5 KB'), findsOneWidget);
    });

    testWidgets('hides question count and tokens when both are zero', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: 0,
            contextTokensCount: 0,
          ),
        ),
      );

      expect(find.textContaining('Questions:'), findsNothing);
      expect(find.textContaining('Tokens:'), findsNothing);
    });

    testWidgets('displays question count when tokens are zero', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: 3,
            contextTokensCount: 0,
          ),
        ),
      );

      expect(find.text('Questions: 3 | Tokens: 0 B'), findsOneWidget);
    });

    testWidgets('displays tokens when question count is zero', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: 0,
            contextTokensCount: 2048,
          ),
        ),
      );

      expect(find.text('Questions: 0 | Tokens: 2.0 KB'), findsOneWidget);
    });

    testWidgets('hides model selector when availableModels is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: <Map<String, dynamic>>[],
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      // Title should still be visible, but model selector should not
      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('llama3.2:3b'), findsNothing);
    });

    testWidgets('contains clear chat button', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
    });

    testWidgets('opens model selector popup when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // Should show popup menu items
      expect(find.text('llama3.2:3b'), findsAtLeastNWidgets(2)); // Selected in both header and popup
      expect(find.text('llama3.2:1b'), findsOneWidget);
    });

    testWidgets('shows check icon next to selected model in popup', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // Find the popup menu item containing the selected model
      final Finder selectedItem = find.ancestor(
        of: find.text('llama3.2:3b').last, // Get the one in popup
        matching: find.byType(PopupMenuItem<String>),
      );

      // Should contain check icon
      expect(
        find.descendant(of: selectedItem, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
    });

    testWidgets('calls onModelSelected when model is selected from popup', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {
              onModelSelectedCalled = true;
              selectedModelValue = model;
            },
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // Tap on the second model
      await tester.tap(find.text('llama3.2:1b'));
      await tester.pumpAndSettle();

      expect(onModelSelectedCalled, true);
      expect(selectedModelValue, 'llama3.2:1b');
    });

    testWidgets('displays model size in chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAiHeader(
            availableModels: mockModels,
            selectedModel: selectedModel,
            onModelSelected: (String model) {},
            onClearChat: () {},
            questionCount: questionCount,
            contextTokensCount: contextTokensCount,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // Should display model sizes (2.0 GB and 1.0 GB as formatted)
      expect(find.text('2.0 GB'), findsOneWidget);
      expect(find.text('1.0 GB'), findsOneWidget);
    });
  });
}
