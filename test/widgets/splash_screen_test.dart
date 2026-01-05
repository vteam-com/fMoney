import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/panels/splash_page.dart';

void main() {
  testWidgets('SplashScreen displays title and progress indicator', (
    WidgetTester tester,
  ) async {
    // Arrange: Build the SplashScreen widget.
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    // Act: Trigger a frame.
    // await tester.pumpAndSettle();

    // Assert: Verify the title text is displayed.
    expect(find.text('fMoney'), findsOneWidget);

    // Assert: Verify the CircularProgressIndicator is displayed.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
