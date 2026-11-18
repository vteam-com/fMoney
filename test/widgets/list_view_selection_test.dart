import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widgets_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/widgets/list/column_widths_notifier.dart';
import 'package:money/widgets/list/list_view.dart';

void main() {
  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  tearDown(() {
    Data().clearExistingData();
    DataFileController.instance = null;
  });

  testWidgets('ticking a row checkbox notifies the selection change once', (WidgetTester tester) async {
    final Payee payee = Payee()
      ..uniqueId = 1
      ..fieldName.value = 'Grocer';
    final ValueNotifier<List<int>> selectedIds = ValueNotifier<List<int>>(<int>[]);
    final ScrollController scrollController = ScrollController();
    final List<int> notifications = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyListView<Payee>(
            fields: Payee.fieldsForColumnView.definitions,
            list: <Payee>[payee],
            selectedItemIds: selectedIds,
            scrollController: scrollController,
            columnWidths: ColumnWidthsNotifier.fromFields(Payee.fieldsForColumnView.definitions),
            widgetBuilders: entityWidgetBuilders,
            isMultiSelectionOn: true,
            onSelectionChanged: notifications.add,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(notifications, <int>[1]);
    expect(selectedIds.value, <int>[1]);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(notifications, <int>[1, 1]);
    expect(selectedIds.value, isEmpty);

    scrollController.dispose();
    selectedIds.dispose();
  });
}
