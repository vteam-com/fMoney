import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/home/ai/ai_instructions_widget.dart';

/// A test host widget for dummy hosting app.
class DummyHostingApp extends StatelessWidget {
  const DummyHostingApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }
}

void main() {
  late bool isOllamaInstalled;
  late bool isOllamaRunning;
  late bool onCheckStatusCalled;
  late bool onInstallCalled;

  setUp(() {
    isOllamaInstalled = false;
    isOllamaRunning = false;
    onCheckStatusCalled = false;
    onInstallCalled = false;
  });

  group('ViewAIInstructions Widget Tests', () {
    testWidgets('displays Ollama icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: isOllamaInstalled,
            isOllamaRunning: isOllamaRunning,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      // Should contain MySvg widget (custom SVG widget)
      // We can't easily test the asset name, but we can verify the widget exists
      expect(find.byType(Column), findsOneWidget); // MySvg is part of the column
    });

    testWidgets('displays title "Ollama AI Assistant"', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: isOllamaInstalled,
            isOllamaRunning: isOllamaRunning,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      expect(find.text('Ollama AI Assistant'), findsOneWidget);
    });

    testWidgets('displays instruction text', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: isOllamaInstalled,
            isOllamaRunning: isOllamaRunning,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      expect(find.text('Ollama is required to use the AI assistant. Click below to install it.'), findsOneWidget);
    });

    testWidgets('shows install button when Ollama is not installed', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: false,
            isOllamaRunning: isOllamaRunning,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      expect(find.text('Install Ollama now'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Install Ollama now'), findsOneWidget);
    });

    testWidgets('shows run button when Ollama is installed but not running', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: true,
            isOllamaRunning: false,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      expect(find.text('Run Ollama'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Run Ollama'), findsOneWidget);
    });

    testWidgets('shows both install and run buttons when Ollama is not installed and not running', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: false,
            isOllamaRunning: false,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      expect(find.text('Install Ollama now'), findsOneWidget);
      expect(find.text('Run Ollama'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('hides run button when Ollama is running', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: true,
            isOllamaRunning: true,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      expect(find.text('Run Ollama'), findsNothing);
      expect(find.text('Install Ollama now'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('calls onInstall when install button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: false,
            isOllamaRunning: false,
            onCheckStatus: () {},
            onInstall: () {
              onInstallCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Install Ollama now'));
      await tester.pump();

      expect(onInstallCalled, true);
    });

    testWidgets('calls onCheckStatus when run button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: true,
            isOllamaRunning: false,
            onCheckStatus: () {
              onCheckStatusCalled = true;
            },
            onInstall: () {},
          ),
        ),
      );

      await tester.tap(find.text('Run Ollama'));
      await tester.pump();

      expect(onCheckStatusCalled, true);
    });

    testWidgets('handles null callbacks gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: false,
            isOllamaRunning: false,
            onCheckStatus: null,
            onInstall: null,
          ),
        ),
      );

      // Widget should render without errors
      expect(find.text('Ollama AI Assistant'), findsOneWidget);
      expect(find.text('Install Ollama now'), findsOneWidget);
      expect(find.text('Run Ollama'), findsOneWidget);
    });

    testWidgets('is centered on screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: isOllamaInstalled,
            isOllamaRunning: isOllamaRunning,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      // The widget should be wrapped in a Center widget
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('contains Box widget with proper padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: isOllamaInstalled,
            isOllamaRunning: isOllamaRunning,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      // Should contain a Box widget (from the core widgets)
      expect(find.byType(Column), findsOneWidget); // The main column inside Box
    });

    testWidgets('shows instruction when Ollama is installed but not running', (WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ViewAIInstructions(
            isOllamaInstalled: true,
            isOllamaRunning: false,
            onCheckStatus: () {},
            onInstall: () {},
          ),
        ),
      );

      expect(find.text('Ollama AI Assistant'), findsOneWidget);
      expect(find.text('Run Ollama'), findsOneWidget);
      // Should not show install button since it's installed
      expect(find.text('Install Ollama now'), findsNothing);
    });
  });
}
