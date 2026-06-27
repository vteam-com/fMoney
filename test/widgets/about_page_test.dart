import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/screens/about_screen.dart';

void main() {
  group('About Page Tests', () {
    testWidgets('About page renders without crashing', (WidgetTester tester) async {
      // Build the about page
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutPage(),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Test that the page renders without crashing
      expect(find.byType(AboutPage), findsOneWidget, reason: 'About page should render');
      expect(find.byType(AppBar), findsOneWidget, reason: 'Should have an AppBar');
      expect(find.byType(SingleChildScrollView), findsOneWidget, reason: 'Should be scrollable');
    });

    testWidgets('About page shows static version information immediately', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutPage(),
        ),
      );

      // Static version data should render without async loading.
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'Should not show loading indicator when version data is generated at build time',
      );

      // Wait for frame completion.
      await tester.pumpAndSettle();

      expect(find.byType(AboutPage), findsOneWidget, reason: 'About page should render');
    });

    testWidgets('About page has correct structure with cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Test that all sections are in cards
      expect(find.byType(Card), findsNWidgets(3), reason: 'Should have 3 cards for each section');

      // Test that cards have padding
      final Iterable<Card> cards = tester.widgetList(find.byType(Card));
      for (final Card card in cards) {
        expect(card.child, isA<Padding>(), reason: 'Each card should have padding');
      }
    });

    testWidgets('About page is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Test that the page is scrollable
      expect(find.byType(SingleChildScrollView), findsOneWidget, reason: 'About page should be scrollable');

      // Test scrolling functionality
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -200), 1000);
      await tester.pumpAndSettle();

      // Should still be rendered after scrolling
      expect(find.byType(AboutPage), findsOneWidget, reason: 'About page should still be visible after scrolling');
    });

    testWidgets('About page has proper AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Test AppBar structure
      expect(find.byType(AppBar), findsOneWidget, reason: 'Should have an AppBar');

      final AppBar appBar = tester.widget(find.byType(AppBar));
      expect(appBar.title, isNotNull, reason: 'AppBar should have a title');
    });

    testWidgets('About page renders version information card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Static data should never show an async loading indicator.
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'Should not show loading indicator',
      );

      // Should render version information section
      expect(find.byType(Card), findsNWidgets(3), reason: 'Should have all 3 sections rendered');
    });
  });
}
