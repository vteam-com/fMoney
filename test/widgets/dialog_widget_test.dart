import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';

void main() {
  /// Pumps a [MyAlertDialog] with two actions in a window [width] wide.
  Future<void> pumpDialog(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyAlertDialog(
            title: 'Title',
            actions: <Widget>[
              TextButton(onPressed: () {}, child: const Text('One')),
              TextButton(onPressed: () {}, child: const Text('Two')),
            ],
            child: const Text('Body'),
          ),
        ),
      ),
    );
  }

  testWidgets('the dialog frame lays its actions out in the shared end-aligned row', (WidgetTester tester) async {
    await pumpDialog(tester, 1100);

    final OverflowBar row = tester.widget<OverflowBar>(find.byType(OverflowBar));
    expect(row.alignment, MainAxisAlignment.end);
    expect(row.overflowAlignment, OverflowBarAlignment.end);
    expect(row.spacing, SizeForPadding.normal);
    expect(tester.widget<Dialog>(find.byType(Dialog)).insetPadding, isNull);
  });

  testWidgets('on a small screen the dialog frame spans the window', (WidgetTester tester) async {
    await pumpDialog(tester, 400);

    expect(tester.widget<Dialog>(find.byType(Dialog)).insetPadding, EdgeInsets.zero);
  });
}
