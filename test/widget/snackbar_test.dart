import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money/widgets/pure/snack_bar.dart';
import 'package:money/widgets/pure/theme_custom.dart';
import 'package:money/widgets/theme_controller.dart';

/// A mock used in tests for mock theme controller.
class MockThemeController extends GetxController implements ThemeController {
  @override
  RxInt colorSelected = 0.obs;

  @override
  RxBool isDarkTheme = false.obs;

  @override
  RxBool isDeviceWidthLarge = false.obs;

  @override
  RxBool isDeviceWidthMedium = true.obs;

  @override
  RxBool isDeviceWidthSmall = false.obs;

  @override
  Color primaryColor = Colors.grey;

  bool get isDarkMode => false;

  double get textScale => 1.0;

  @override
  void adjustFontScale(double delta) {}

  @override
  void fontScaleDecrease() {}

  @override
  void fontScaleIncrease() {}

  @override
  void loadThemeFromPreferences() {}

  @override
  void saveThemeToPreferences() {}

  @override
  void setAppSizeToLarge() {}

  @override
  void setAppSizeToMedium() {}

  @override
  void setAppSizeToSmall() {}

  @override
  bool setFontScaleTo(double newScale) => true;

  @override
  void setThemeColor(int index) {}

  @override
  ThemeData get themeData => ThemeData.light();

  @override
  ThemeData get themeDataDark => ThemeData.dark();

  @override
  ThemeData get themeDataLight => ThemeData.light();

  void toggleTheme() {}

  @override
  void toggleThemeMode() {}

  @override
  void updateTheme() {}
}

void main() {
  setUp(() {
    // Register mock ThemeController for tests
    Get.put<ThemeController>(MockThemeController());
  });

  tearDown(() {
    Get.reset();
  });
  group('SnackBarService', () {
    testWidgets('displays custom snackbar correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: SnackBarService.scaffoldKey,
          theme: ThemeData.light().copyWith(
            extensions: <ThemeExtension<dynamic>>[
              const MoneyThemeData(
                success: Colors.green,
                warning: Colors.amber,
                error: Colors.red,
                disabled: Colors.grey,
                quantityPositive: Colors.blue,
                quantityNegative: Colors.orange,
                info: Colors.lightBlue,
              ),
            ],
          ),
          home: Scaffold(
            body: Builder(
              builder: (final BuildContext context) => ElevatedButton(
                onPressed: () => SnackBarService.display(
                  title: 'Test Title',
                  message: 'Test message',
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Show Snackbar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test message'), findsOneWidget);
      expect(find.byKey(const Key('key_snackbar')), findsOneWidget);
    });

    testWidgets('can close snackbar with close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: SnackBarService.scaffoldKey,
          theme: ThemeData.light().copyWith(
            extensions: <ThemeExtension<dynamic>>[
              const MoneyThemeData(
                success: Colors.green,
                warning: Colors.amber,
                error: Colors.red,
                disabled: Colors.grey,
                quantityPositive: Colors.blue,
                quantityNegative: Colors.orange,
                info: Colors.lightBlue,
              ),
            ],
          ),
          home: Scaffold(
            body: Builder(
              builder: (final BuildContext context) => ElevatedButton(
                onPressed: () => SnackBarService.display(
                  title: 'Test',
                  message: 'Test message',
                ),
                child: const Text('Show Snackbar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);

      // Close the snackbar
      await tester.tap(find.byKey(const Key('key_snackbar_close_button')));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsNothing);
    });

    testWidgets('skips snackbar display in testing mode', (WidgetTester tester) async {
      // Enable testing mode
      SnackBarService.enableTestingMode();

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: SnackBarService.scaffoldKey,
          home: Scaffold(
            body: Builder(
              builder: (final BuildContext context) => ElevatedButton(
                onPressed: () => SnackBarService.display(
                  title: 'Hidden',
                  message: 'This should not appear',
                ),
                child: const Text('Show Snackbar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Snackbar should not appear in testing mode
      expect(find.text('Hidden'), findsNothing);
      expect(find.text('This should not appear'), findsNothing);

      // Disable testing mode for other tests
      SnackBarService.disableTestingMode();
    });

    testWidgets('custom snackbar with action works', (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: SnackBarService.scaffoldKey,
          theme: ThemeData.light().copyWith(
            extensions: <ThemeExtension<dynamic>>[
              const MoneyThemeData(
                success: Colors.green,
                warning: Colors.amber,
                error: Colors.red,
                disabled: Colors.grey,
                quantityPositive: Colors.blue,
                quantityNegative: Colors.orange,
                info: Colors.lightBlue,
              ),
            ],
          ),
          home: Scaffold(
            body: Builder(
              builder: (final BuildContext context) => ElevatedButton(
                onPressed: () => SnackBarService.display(
                  title: 'Custom',
                  message: 'Custom message',
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => actionPressed = true,
                  ),
                ),
                child: const Text('Show Custom Snackbar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Custom message'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      expect(actionPressed, isTrue);
    });
  });
}
