// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/views/screens/home/view_cashflow.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

/// A test host widget for dummy hosting app.
class DummyHostingApp extends StatefulWidget {
  const DummyHostingApp({super.key});

  @override
  DummyHostingAppState createState() => DummyHostingAppState();
}

/// State used by dummy hosting app in tests.
class DummyHostingAppState extends State<DummyHostingApp> {
  final PreferenceController preferenceController = PreferenceController();
  final ThemeController themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    PreferenceController.instance = preferenceController;
    ThemeController.instance = themeController;
  }

  @override
  void dispose() {
    PreferenceController.instance = null;
    ThemeController.instance = null;
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    Data().recalculateBalances();
    return const MaterialApp(
      home: SizedBox(
        height: 600,
        width: 800,
        child: Column(children: <Widget>[Expanded(child: ViewCashFlow())]),
      ),
    );
  }
}

void main() {
  testWidgets('Cash Flow widget', (final WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DummyHostingApp());
    expect(find.text('Cash Flow', skipOffstage: false), findsOneWidget);
  });
}
