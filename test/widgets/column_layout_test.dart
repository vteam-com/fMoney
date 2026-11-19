import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/widgets/list/column_resize_handle_widget.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';
import 'package:money/widgets/list/list_view.dart';
import 'package:money/widgets/widgets_domain/data_object_widget_builders_model.dart';

/// Minimal row for the list body.
class _Row extends DataObject {
  int _id = 1;

  @override
  int get uniqueId => _id;

  @override
  set uniqueId(int value) => _id = value;
}

/// Builders that always fall back to the generic field widgets.
final DataObjectWidgetBuilders _genericBuilders = DataObjectWidgetBuilders(
  buildFieldWidget: (DataObject _, Field<dynamic> _) => null,
  buildEditWidget: (DataObject _, Field<dynamic> _, void Function(bool) _) => null,
  buildSmallScreen: (DataObject _) => const SizedBox(),
);

/// Returns a text column named and showing [name], optionally [hidden].
Field<dynamic> _column(String name, {bool hidden = false}) => Field<dynamic>(
  type: FieldType.text,
  name: name,
  defaultValue: '',
  columnWidth: hidden ? ColumnWidth.hidden : ColumnWidth.normal,
  getValueForDisplay: (dynamic _) => name,
);

/// Pumps a one-row list body showing [fields].
Future<void> _pumpBody(WidgetTester tester, FieldDefinitions fields, ScrollController scrollController) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MyListView<DataObject>(
          fields: fields,
          list: <DataObject>[_Row()],
          selectedItemIds: ValueNotifier<List<int>>(<int>[]),
          scrollController: scrollController,
          columnWidths: ColumnWidthsNotifier.fromFields(fields),
          widgetBuilders: _genericBuilders,
        ),
      ),
    ),
  );
}

void main() {
  group('buildVisibleColumnCells', () {
    test('skips hidden columns, sizes cells by ratio and puts a gap between neighbours', () {
      final List<String> built = <String>[];
      buildVisibleColumnCells(
        fields: <Field<dynamic>>[_column('A'), _column('B', hidden: true), _column('C')],
        ratios: <double>[0.25, 0.75],
        maxWidth: 200 + columnResizeHandleWidth,
        buildCell: (int fieldIndex, double width) {
          built.add('cell $fieldIndex $width');
          return const SizedBox();
        },
        buildGap: (int leftColumnPosition, double contentWidth) {
          built.add('gap $leftColumnPosition $contentWidth');
          return const SizedBox();
        },
      );

      expect(built, <String>['cell 0 50.0', 'gap 0 200.0', 'cell 2 150.0']);
    });

    test('counts gaps from the visible fields, and a column without a ratio gets no width', () {
      final List<Widget> cells = buildVisibleColumnCells(
        fields: <Field<dynamic>>[_column('A'), _column('B'), _column('C')],
        ratios: <double>[1],
        maxWidth: 100,
        buildCell: (int _, double width) => SizedBox(width: width),
        buildGap: (int _, double _) => const Divider(),
      );

      expect(cells.whereType<Divider>().length, 2);
      expect(cells.whereType<SizedBox>().map((SizedBox box) => box.width), <double>[
        100 - 2 * columnResizeHandleWidth,
        0,
        0,
      ]);
    });
  });

  group('ColumnResizeHandle', () {
    testWidgets('dragging moves the boundary between its two columns', (WidgetTester tester) async {
      final ColumnWidthsNotifier widths = ColumnWidthsNotifier(<double>[0.5, 0.5]);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              height: 20,
              child: ColumnResizeHandle(
                columnWidths: widths,
                leftColumnPosition: 0,
                contentWidth: 200,
                showDivider: true,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(VerticalDivider), findsOneWidget);

      await tester.drag(find.byType(ColumnResizeHandle), const Offset(40, 0));

      expect(widths.value.first, greaterThan(0.5));
      expect(widths.value.first + widths.value.last, closeTo(1, 1e-9));
      widths.dispose();
    });

    testWidgets('the body handle draws no divider', (WidgetTester tester) async {
      final ColumnWidthsNotifier widths = ColumnWidthsNotifier(<double>[0.5, 0.5]);
      await tester.pumpWidget(
        MaterialApp(
          home: ColumnResizeHandle(columnWidths: widths, leftColumnPosition: 0, contentWidth: 200),
        ),
      );
      expect(find.byType(VerticalDivider), findsNothing);
      widths.dispose();
    });
  });

  testWidgets('the list body follows a column hidden without changing the number of fields', (
    WidgetTester tester,
  ) async {
    final ScrollController scrollController = ScrollController();

    await _pumpBody(tester, <Field<dynamic>>[_column('A'), _column('B'), _column('C')], scrollController);
    expect(find.text('B'), findsOneWidget);
    expect(find.byType(ColumnResizeHandle), findsNWidgets(2));

    await _pumpBody(tester, <Field<dynamic>>[_column('A'), _column('B', hidden: true), _column('C')], scrollController);
    expect(find.text('B'), findsNothing);
    expect(find.text('C'), findsOneWidget);
    expect(find.byType(ColumnResizeHandle), findsOneWidget);

    scrollController.dispose();
  });
}
