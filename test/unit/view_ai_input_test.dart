import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/pure/chat_input_area_widget.dart';

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
  late TextEditingController inputController;
  late bool onSendPromptCalled;
  late bool onCancelCalled;
  late bool onToggleSelectAllCalled;
  late int? toggledAccountId;
  late String sentPromptText;

  setUp(() {
    inputController = TextEditingController();
    onSendPromptCalled = false;
    onCancelCalled = false;
    onToggleSelectAllCalled = false;
    toggledAccountId = null;
    sentPromptText = '';
  });

  tearDown(() {
    inputController.dispose();
  });

  /// Creates the chat input area under test with overridable callbacks and state.
  Widget buildWidget({
    bool processing = false,
    Map<String, Map<int, String>> accountGroupsByLabel = const <String, Map<int, String>>{
      'Banking': <int, String>{
        1: 'Checking',
        2: 'Savings',
      },
      'Credit': <int, String>{
        3: 'Visa',
      },
    },
    Set<int> selectedAccountIds = const <int>{},
    bool selectAllAccounts = true,
  }) {
    return DummyHostingApp(
      child: ChatInputArea(
        inputController: inputController,
        onSendPrompt: (String prompt) {
          onSendPromptCalled = true;
          sentPromptText = prompt;
        },
        isProcessing: processing,
        onCancel: () {
          onCancelCalled = true;
        },
        accountGroupsByLabel: accountGroupsByLabel,
        selectedAccountIds: selectedAccountIds,
        selectAllAccounts: selectAllAccounts,
        onToggleAccountSelection: (int accountId) {
          toggledAccountId = accountId;
        },
        onToggleSelectAllAccounts: () {
          onToggleSelectAllCalled = true;
        },
      ),
    );
  }

  group('ChatInputArea Widget Tests', () {
    testWidgets('displays preset buttons', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text(AppL10n.tr(AppTranslationKeys.accountNames)), findsOneWidget);
      expect(find.text(AppL10n.tr(AppTranslationKeys.largestTransactions)), findsOneWidget);
      expect(find.text(AppL10n.tr(AppTranslationKeys.analyzeSpending)), findsOneWidget);
      expect(find.text(AppL10n.tr(AppTranslationKeys.expensePredictions)), findsOneWidget);
    });

    testWidgets('displays all accounts in dropdown caption when selecting all', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      final String caption =
          '${AppL10n.tr(AppTranslationKeys.allLabel)} ${AppL10n.tr(AppTranslationKeys.accounts).toLowerCase()}';
      expect(find.text(caption), findsOneWidget);
    });

    testWidgets('displays selected account count in dropdown caption', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          selectAllAccounts: false,
          selectedAccountIds: const <int>{1},
        ),
      );

      final String caption = '1 ${AppL10n.tr(AppTranslationKeys.account).toLowerCase()}';
      expect(find.text(caption), findsOneWidget);
    });

    testWidgets('opens account menu and selects all', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      final String caption =
          '${AppL10n.tr(AppTranslationKeys.allLabel)} ${AppL10n.tr(AppTranslationKeys.accounts).toLowerCase()}';
      await tester.tap(find.text(caption));
      await tester.pumpAndSettle();

      final Finder allMenuItem = find
          .widgetWithText(CheckedPopupMenuItem<String>, AppL10n.tr(AppTranslationKeys.allLabel))
          .last;
      await tester.ensureVisible(allMenuItem);
      await tester.tap(allMenuItem);
      await tester.pumpAndSettle();

      expect(onToggleSelectAllCalled, true);
    });

    testWidgets('opens account menu and shows grouped account headings', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      final String caption =
          '${AppL10n.tr(AppTranslationKeys.allLabel)} ${AppL10n.tr(AppTranslationKeys.accounts).toLowerCase()}';
      await tester.tap(find.text(caption));
      await tester.pumpAndSettle();

      expect(find.text('Banking').last, findsOneWidget);
      expect(find.text('Credit').last, findsOneWidget);
    });

    testWidgets('opens account menu and selects one account', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(selectAllAccounts: false));

      await tester.tap(find.text('0 ${AppL10n.tr(AppTranslationKeys.accounts).toLowerCase()}'));
      await tester.pumpAndSettle();

      final Finder checkingMenuItem = find.widgetWithText(CheckedPopupMenuItem<String>, 'Checking').last;
      await tester.ensureVisible(checkingMenuItem);
      await tester.tap(checkingMenuItem);
      await tester.pumpAndSettle();

      expect(toggledAccountId, 1);
    });

    testWidgets('displays text input field with proper hint', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(SharedStrings.aiAssistantHint), findsOneWidget);
    });

    testWidgets('shows send button when not processing', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(processing: false));

      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('shows cancel button when processing', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(processing: true));

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('calls onSendPrompt when account names button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.accountNames)));
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, AppL10n.tr(AppTranslationKeys.accountNames));
    });

    testWidgets('calls onSendPrompt when largest transactions button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text(AppL10n.tr(AppTranslationKeys.largestTransactions)));
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, AppL10n.tr(AppTranslationKeys.largestTransactions));
    });

    testWidgets('calls onSendPrompt with text field content when send button is tapped', (
      WidgetTester tester,
    ) async {
      const String testText = 'Test prompt';
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextField), testText);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, testText);
    });

    testWidgets('does not call onSendPrompt when send button is tapped with empty text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(onSendPromptCalled, false);
    });

    testWidgets('calls onSendPrompt when enter is pressed in text field', (WidgetTester tester) async {
      const String testText = 'Test prompt from enter';
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextField), testText);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(onSendPromptCalled, true);
      expect(sentPromptText, testText);
    });

    testWidgets('calls onCancel when cancel button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(processing: true));

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pump();

      expect(onCancelCalled, true);
    });

    testWidgets('shows no-account message in menu when there are no account options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          accountGroupsByLabel: const <String, Map<int, String>>{},
        ),
      );

      final String caption =
          '${AppL10n.tr(AppTranslationKeys.allLabel)} ${AppL10n.tr(AppTranslationKeys.accounts).toLowerCase()}';
      await tester.tap(find.text(caption));
      await tester.pumpAndSettle();

      expect(find.text(AppL10n.tr(AppTranslationKeys.noAccountSelectedPeriod)), findsOneWidget);
    });
  });
}
