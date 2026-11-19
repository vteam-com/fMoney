import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/accumulator_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/widgets/widgets_domain/footer_accumulators_helper.dart';
import 'package:money/widgets/widgets_domain/footer_widgets_helper.dart';

/// Row holding one value [v] that the test fields display.
class _Item extends DataObject {
  /// Creates a row holding [v].
  _Item(this.v);

  dynamic v;
  int _id = -1;

  @override
  int get uniqueId => _id;

  @override
  set uniqueId(int value) => _id = value;
}

/// Returns a column of [type] with a [footer] that displays the row value.
Field<dynamic> _column(FieldType type, FooterType footer) => Field<dynamic>(
  type: type,
  name: 'f',
  defaultValue: null,
  footer: footer,
  getValueForDisplay: (dynamic item) => (item as _Item).v,
);

/// Pumps [build] inside an app wired to [AppRouter] so footer colors resolve.
Future<void> _pumpFooter(WidgetTester tester, Widget Function() build) {
  return tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
      home: Scaffold(body: Builder(builder: (BuildContext _) => build())),
    ),
  );
}

/// Returns the text of every [Text] on screen.
List<String> _shownTexts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((Text text) => text.data ?? '').toList();

void main() {
  group('recomputeIfChanged', () {
    test('re-scans only for a new list or a new data version', () {
      final Field<dynamic> field = _column(FieldType.amount, FooterType.sum);
      final _Item item = _Item(1.0);
      final List<DataObject> items = <DataObject>[item];
      final FooterAccumulators footer = FooterAccumulators();

      footer.recomputeIfChanged(items: items, definitions: <Field<dynamic>>[field], version: 'v1');
      item.v = 5.0;
      footer.recomputeIfChanged(items: items, definitions: <Field<dynamic>>[field], version: 'v1');
      expect(footer.accumulatorSumAmount.getValue(field), 1.0);

      footer.recomputeIfChanged(items: items, definitions: <Field<dynamic>>[field], version: 'v2');
      expect(footer.accumulatorSumAmount.getValue(field), 5.0);

      item.v = 7.0;
      footer.recomputeIfChanged(items: List<DataObject>.of(items), definitions: <Field<dynamic>>[field], version: 'v2');
      expect(footer.accumulatorSumAmount.getValue(field), 7.0);
    });
  });

  group('footer amounts use the column currency', () {
    testWidgets('a large euro sum shows the euro symbol in shorthand', (WidgetTester tester) async {
      final Field<dynamic> field = _column(FieldType.amount, FooterType.sum);
      final FooterAccumulators footer = FooterAccumulators()
        ..recompute(
          items: <DataObject>[_Item(AmountModel(amount: 12345, iso4217: 'EUR'))],
          definitions: <Field<dynamic>>[field],
        );

      await _pumpFooter(tester, () => footer.buildWidget(field));

      expect(_shownTexts(tester), contains('€12.3K'));
    });

    testWidgets('a column mixing currencies falls back to the default currency', (WidgetTester tester) async {
      final Field<dynamic> field = _column(FieldType.amount, FooterType.sum);
      final FooterAccumulators footer = FooterAccumulators()
        ..recompute(
          items: <DataObject>[
            _Item(AmountModel(amount: 5, iso4217: 'EUR')),
            _Item(AmountModel(amount: 5, iso4217: 'CAD')),
          ],
          definitions: <Field<dynamic>>[field],
        );

      await _pumpFooter(tester, () => footer.buildWidget(field));

      expect(_shownTexts(tester), contains('\$10.00'));
    });

    testWidgets('the min/avg/max range shows the column currency', (WidgetTester tester) async {
      final RunningAverage range = RunningAverage()
        ..addValue(10)
        ..addValue(20);

      await _pumpFooter(tester, () => getFooterForNumericRange(range, FieldType.amount, iso4217code: 'EUR'));

      expect(_shownTexts(tester), containsAll(<String>['€10,00', '€15,00', '€20,00']));
    });
  });

  testWidgets('a count footer on a numeric column counts its values', (WidgetTester tester) async {
    final Field<dynamic> field = _column(FieldType.numeric, FooterType.count);
    final FooterAccumulators footer = FooterAccumulators()
      ..recompute(items: <DataObject>[_Item(1), _Item(2)], definitions: <Field<dynamic>>[field]);

    await _pumpFooter(tester, () => footer.buildWidget(field));

    expect(_shownTexts(tester), contains('2'));
  });

  testWidgets('a footer number that is not finite shows a placeholder', (WidgetTester tester) async {
    await _pumpFooter(tester, () => getFooterForInt(double.nan));

    expect(_shownTexts(tester), contains('---'));
  });
}
