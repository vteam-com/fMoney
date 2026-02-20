// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/views/view_cashflow/view_cashflow.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/theme_controller.dart';

/// A test host widget for dummy hosting app.
class DummyHostingApp extends StatefulWidget {
  const DummyHostingApp({super.key});

  @override
  DummyHostingAppState createState() => DummyHostingAppState();
}

/// State used by dummy hosting app in tests.
class DummyHostingAppState extends State<DummyHostingApp> {
  final PreferenceController preferenceController = Get.put(
    PreferenceController(),
  );
  final ThemeController themeController = Get.put(ThemeController());

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
