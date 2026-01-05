import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:money/controller/preferences_controller.dart';
import 'package:money/controller/theme_controller.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/field_type.dart';
import 'package:money/widgets/money_model.dart';
import 'package:money/widgets/money_object.dart';
import 'package:money/widgets/money_widget.dart';
import 'package:money/widgets/quantity_widget.dart';

class MockThemeController extends GetxController with Mock implements ThemeController {
  @override
  RxBool get isDarkTheme => false.obs;
}

class MockPreferenceController extends GetxController with Mock implements PreferenceController {
  @override
  String getString(String key, [String defaultValueIfNotFound = '']) => '';

  @override
  Future<void> setString(
    String key,
    String value, [
    bool removeIfEmpty = false,
  ]) async {
    // do nothing
  }
}

void main() {
  setUp(() {
    // Enable test mode
    Get.testMode = true;

    final MockPreferenceController mockPreferenceController = MockPreferenceController();
    final MockThemeController mockThemeController = MockThemeController();

    Get.put<ThemeController>(mockThemeController);
    Get.put<PreferenceController>(mockPreferenceController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Is Mobile', (final WidgetTester tester) async {
    expect(isPlatformMobile(), false);
  });

  testWidgets('buildFieldWidgetForAmount renders correct text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildFieldWidgetForAmount(value: 1234.56, currency: 'USD'),
        ),
      ),
    );

    expect(find.text('\$1,234.56'), findsOneWidget);
  });

  testWidgets('buildFieldWidgetForAmount renders shorthand text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildFieldWidgetForAmount(value: 1234567, shorthand: true),
        ),
      ),
    );

    expect(find.text('1.23M'), findsOneWidget);
  });

  group('buildWidgetFromTypeAndValue', () {
    testWidgets('renders Text widget for numeric field with String value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: '42',
              type: FieldType.numeric,
              align: TextAlign.left,
              fixedFont: true,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders number widget for numeric field with num value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: 42,
              type: FieldType.numeric,
              align: TextAlign.right,
              fixedFont: false,
            ),
          ),
        ),
      );

      expect(find.byType(FittedBox), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders number widget for numericShorthand field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: 1234567,
              type: FieldType.numericShorthand,
              align: TextAlign.center,
              fixedFont: false,
            ),
          ),
        ),
      );

      expect(find.byType(FittedBox), findsOneWidget);
      expect(find.text('1.23M'), findsOneWidget);
    });

    testWidgets('renders quantity widget for quantity field with num value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: 42.0,
              type: FieldType.quantity,
              align: TextAlign.left,
              fixedFont: false,
            ),
          ),
        ),
      );

      expect(find.byType(QuantityWidget), findsOneWidget);
    });

    testWidgets('renders Text widget for quantity field with String value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: 'text',
              type: FieldType.quantity,
              align: TextAlign.right,
              fixedFont: false,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      expect(find.text('text'), findsOneWidget);
    });

    testWidgets('renders percentage widget for percentage field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: 0.42,
              type: FieldType.percentage,
              align: TextAlign.left,
              fixedFont: false,
            ),
          ),
        ),
      );

      final String s = (0.42 * 100).toStringAsFixed(3);
      expect(s, '42.000');

      expect(find.byType(Row), findsOneWidget);
      expect(find.text(s), findsOneWidget);
    });

    testWidgets('renders Text widget for amount field with String value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: '1,234.56',
              type: FieldType.amount,
              align: TextAlign.right,
              fixedFont: true,
              currency: 'USD',
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      expect(find.text('1,234.56'), findsOneWidget);
    });

    testWidgets('renders MoneyWidget for amount field with MoneyModel value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: MoneyModel(amount: 1234.56, iso4217: 'USD'),
              type: FieldType.amount,
              align: TextAlign.left,
              fixedFont: false,
              currency: 'USD',
            ),
          ),
        ),
      );

      expect(find.byType(MoneyWidget), findsOneWidget);
    });

    testWidgets('renders MoneyWidget for amount field with num value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: 1234.56,
              type: FieldType.amount,
              align: TextAlign.center,
              fixedFont: false,
              currency: 'USD',
            ),
          ),
        ),
      );

      expect(find.byType(MoneyWidget), findsOneWidget);
    });

    testWidgets('renders amount widget for amountShorthand field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: 1234567,
              type: FieldType.amountShorthand,
              align: TextAlign.right,
              fixedFont: false,
              currency: 'USD',
            ),
          ),
        ),
      );

      final String result = getAmountAsShorthandText(1234567);
      expect(result, '1.23M');

      expect(find.byType(FittedBox), findsOneWidget);
      expect(find.text('1.23M'), findsOneWidget);
    });

    testWidgets('renders the provided widget for widget field', (
      WidgetTester tester,
    ) async {
      const Text testWidget = Text('Test Widget');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: testWidget,
              type: FieldType.widget,
              align: TextAlign.left,
              fixedFont: false,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      expect(find.text('Test Widget'), findsOneWidget);
    });

    testWidgets('renders Text widget for date field with String value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: '2023-05-15',
              type: FieldType.date,
              align: TextAlign.right,
              fixedFont: true,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      expect(find.text('2023-05-15'), findsOneWidget);
    });

    testWidgets('renders date widget for date field with DateTime value', (
      WidgetTester tester,
    ) async {
      final DateTime inputDate = DateTime(2023, 5, 15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: inputDate,
              type: FieldType.date,
              align: TextAlign.left,
              fixedFont: false,
            ),
          ),
        ),
      );

      final String result = dateToString(inputDate);
      expect(result, '2023-05-15');

      expect(find.byType(FittedBox), findsOneWidget);
      expect(find.text(result), findsOneWidget);
    });

    testWidgets('renders Text widget for text field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildWidgetFromTypeAndValue(
              value: 'text',
              type: FieldType.text,
              align: TextAlign.center,
              fixedFont: true,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      expect(find.text('text'), findsOneWidget);
    });
  });
}
