import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/event_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/views/panels/charts/net_worth_chart.dart';
import 'package:money/widgets/charts/chart_event_model.dart';

void main() {
  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  test('chartEventsFromEvents spans each event, colors it by category and sorts by begin date', () {
    final Category travel = Category(
      id: 5,
      name: 'Travel',
      type: CategoryType.expense,
      color: '#FF00FF00',
      data: Data(),
    );
    Data().categories.appendMoneyObject(travel);

    final List<ChartEvent> chartEvents = chartEventsFromEvents(<Event>[
      Event(
        id: 1,
        name: 'Ongoing',
        dateBegin: DateTime(2024, 5, 1),
        dateEnd: null,
        people: '',
        memo: '',
        data: Data(),
      ),
      Event(
        id: 2,
        name: 'Trip',
        categoryId: 5,
        dateBegin: DateTime(2023, 2, 1),
        dateEnd: DateTime(2023, 2, 10),
        people: '',
        memo: '',
        data: Data(),
      ),
    ]);

    expect(chartEvents.map((ChartEvent e) => e.description), <String>['Trip', 'Ongoing']);
    expect(chartEvents.first.dates.min, DateTime(2023, 2, 1));
    expect(chartEvents.first.dates.max, DateTime(2023, 2, 10));
    expect(chartEvents.first.colorToUse, travel.getColorOrAncestorsColor());
    expect(chartEvents.last.dates.max, isNotNull);
    expect(chartEvents.last.colorToUse, Colors.blue);
  });
}
