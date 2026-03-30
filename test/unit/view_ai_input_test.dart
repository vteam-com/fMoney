import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/pure/chat_input_area.dart';

/// A test host widget for dummy hosting app.
class DummyHostingApp extends StatelessWidget {
  const DummyHostingApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }
}

void main() {
  late TextEditingController inputController;
  late bool isProcessing;
  late bool onSendPromptCalled;
  late bool onCancelCalled;
  late bool onTeachAICalled;
  late String sentPromptText;

  setUp(() {
    inputController = TextEditingController();
    isProcessing = false;
    onSendPromptCalled = false;
    onCancelCalled = false;
    onTeachAICalled = false;
    sentPromptText = '';
  });

  tearDown(() {
    inputController.dispose();
  });

  group('ChatInputArea Widget Tests', () {
    testWidgets('displays preset buttons', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {
              onSendPromptCalled = true;
              sentPromptText = prompt;
            },
            isProcessing: isProcessing,
            onCancel: () {
              onCancelCalled = true;
            },
            onTeachAI: () {
              onTeachAICalled = true;
            },
          ),
        ),
      );

      expect(find.text('Account names'), findsOneWidget);
      expect(find.text('Largest transactions'), findsOneWidget);
      expect(find.text('Analyze spending'), findsOneWidget);
      expect(find.text('Expense predictions'), findsOneWidget);
    });

    testWidgets('displays teach AI button', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      expect(find.text('BankAccounts'), findsOneWidget);
    });

    testWidgets('displays text input field with proper hint', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask the AI assistant...'), findsOneWidget);
    });

    testWidgets('shows send button when not processing', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: false,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('shows cancel button when processing', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: true,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('calls onSendPrompt when account names button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {
              onSendPromptCalled = true;
              sentPromptText = prompt;
            },
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      await tester.tap(find.text('Account names'));
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, 'List all the account names');
    });

    testWidgets('calls onSendPrompt when largest transactions button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {
              onSendPromptCalled = true;
              sentPromptText = prompt;
            },
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      await tester.tap(find.text('Largest transactions'));
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, 'Identify the largest single transaction amount in each account');
    });

    testWidgets('calls onSendPrompt when analyze spending button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {
              onSendPromptCalled = true;
              sentPromptText = prompt;
            },
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      await tester.tap(find.text('Analyze spending'));
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, 'Analyze my spending patterns');
    });

    testWidgets('calls onSendPrompt when expense predictions button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {
              onSendPromptCalled = true;
              sentPromptText = prompt;
            },
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      await tester.tap(find.text('Expense predictions'));
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, 'Predict future expenses');
    });

    testWidgets('calls onSendPrompt with text field content when send button is tapped', (
      final WidgetTester tester,
    ) async {
      const String testText = 'Test prompt';

      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {
              onSendPromptCalled = true;
              sentPromptText = prompt;
            },
            isProcessing: false,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      // Enter text in the text field
      await tester.enterText(find.byType(TextField), testText);

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, testText);
    });

    testWidgets('does not call onSendPrompt when send button is tapped with empty text', (
      final WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {
              onSendPromptCalled = true;
              sentPromptText = prompt;
            },
            isProcessing: false,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      // Tap send button with empty text
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(onSendPromptCalled, false);
    });

    testWidgets('calls onSendPrompt when enter is pressed in text field', (final WidgetTester tester) async {
      const String testText = 'Test prompt from enter';

      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {
              onSendPromptCalled = true;
              sentPromptText = prompt;
            },
            isProcessing: false,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      // Enter text and submit
      await tester.enterText(find.byType(TextField), testText);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, testText);
    });

    testWidgets('calls onCancel when cancel button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: true,
            onCancel: () {
              onCancelCalled = true;
            },
            onTeachAI: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pump();

      expect(onCancelCalled, true);
    });

    testWidgets('calls onTeachAI when teach AI button is tapped', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {
              onTeachAICalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('BankAccounts'));
      await tester.pump();

      expect(onTeachAICalled, true);
    });

    testWidgets('has proper container styling', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      // Should have a Container with proper styling
      expect(find.byType(Container), findsOneWidget);

      // Should have proper Row layout (one for the preset buttons area might use Row internally)
      expect(find.byType(Row), findsAtLeastNWidgets(1)); // At least one Row for input area

      // Should have Wrap for preset buttons
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('text field has proper decoration', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      // Should have a TextField with OutlineInputBorder
      final TextField textField = tester.widget<TextField>(find.byType(TextField));

      expect(textField.decoration?.hintText, 'Ask the AI assistant...');
      expect(textField.decoration?.border, isA<OutlineInputBorder>());
    });

    testWidgets('preset buttons are ElevatedButtons', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      // Should have 4 ElevatedButton widgets for preset prompts
      expect(find.byType(ElevatedButton), findsNWidgets(4));
    });

    testWidgets('teach AI button is OutlinedButton', (final WidgetTester tester) async {
      await tester.pumpWidget(
        DummyHostingApp(
          child: ChatInputArea(
            inputController: inputController,
            onSendPrompt: (final String prompt) {},
            isProcessing: isProcessing,
            onCancel: () {},
            onTeachAI: () {},
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });
}
