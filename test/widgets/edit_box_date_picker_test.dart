import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/widgets/pickers/edit_box_date_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

/// Owner of a [PickerEditBoxDate] that keeps the picked date, like the edit dialogs do.
class _DateOwner extends StatefulWidget {
  /// Creates an owner starting on [initialDate].
  const _DateOwner({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_DateOwner> createState() => _DateOwnerState();
}

/// State of [_DateOwner].
class _DateOwnerState extends State<_DateOwner> {
  late DateTime? date = widget.initialDate;

  /// Changes the date from outside the edit box.
  void setDate(DateTime newDate) => setState(() => date = newDate);

  @override
  Widget build(BuildContext context) {
    return PickerEditBoxDate(
      initialValue: dateToString(date),
      onChanged: (String text) => setState(() => date = attemptToGetDateFromText(text)),
    );
  }
}

/// Returns the text currently shown in the edit box.
String _shownText(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  group('showOwnerValueChange', () {
    test('copies a changed owner value, caret at the end', () {
      final TextEditingController controller = TextEditingController(text: 'old');
      showOwnerValueChange(controller, 'old', 'new');
      expect(controller.text, 'new');
      expect(controller.selection, const TextSelection.collapsed(offset: 3));
      controller.dispose();
    });

    test('keeps the typed text while the owner value is unchanged or already shown', () {
      final TextEditingController controller = TextEditingController(text: 'typed');
      showOwnerValueChange(controller, 'same', 'same');
      expect(controller.text, 'typed');
      showOwnerValueChange(
        controller,
        'old',
        'TYPED',
        isSameValue: (String a, String b) => a.toLowerCase() == b.toLowerCase(),
      );
      expect(controller.text, 'typed');
      controller.dispose();
    });
  });

  group('PickerEditBoxDate', () {
    testWidgets('shows a date the owner changed from outside', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _DateOwner(initialDate: DateTime(2024))),
        ),
      );
      expect(_shownText(tester), '2024-01-01');

      tester.state<_DateOwnerState>(find.byType(_DateOwner)).setDate(DateTime(2024, 2, 2));
      await tester.pump();

      expect(_shownText(tester), '2024-02-02');
    });

    testWidgets('keeps what the user types when the owner echoes it back', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _DateOwner(initialDate: DateTime(2024))),
        ),
      );

      await tester.enterText(find.byType(TextField), '2024-03-1');
      await tester.pump();
      expect(_shownText(tester), '2024-03-1');

      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      expect(_shownText(tester), '1');
    });

    testWidgets('opens the calendar on the date typed in the box', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PickerEditBoxDate(initialValue: '2024-01-01', onChanged: (String _) {}),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '2023-06-15');
      await tester.tap(find.byIcon(Icons.edit_calendar));
      await tester.pumpAndSettle();

      expect(find.text('June 2023'), findsOneWidget);
    });
  });
}
