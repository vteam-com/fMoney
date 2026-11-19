import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/shell/navigation_bar_widget.dart';
import 'package:money/views/shell/navigation_item_model.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  late AppServices services;

  setUp(() {
    resetTestData();
    services = createTestServices();
  });

  tearDown(() => disposeTestServices(services));

  /// Pumps a navigation bar laid out along [orientation] showing [selectedView]; picks land in [picked].
  Future<MyNavigationBar> pumpNavigationBar(
    WidgetTester tester, {
    required Axis orientation,
    required ViewId selectedView,
    required List<ViewId> picked,
  }) async {
    final MyNavigationBar bar = MyNavigationBar(
      orientation: orientation,
      selectedView: selectedView,
      onSelected: picked.add,
    );
    await pumpTestApp(tester, services, orientation == Axis.vertical ? Row(children: <Widget>[bar]) : bar);
    return bar;
  }

  for (final Axis orientation in Axis.values) {
    testWidgets('with rentals disabled, every $orientation destination opens its own view', (
      WidgetTester tester,
    ) async {
      expect(services.preferenceController.includeRentalManagement, isFalse);
      final List<ViewId> picked = <ViewId>[];
      final MyNavigationBar bar = await pumpNavigationBar(
        tester,
        orientation: orientation,
        selectedView: ViewId.viewCashFlow,
        picked: picked,
      );
      final List<MyNavigationItem> items = bar.getAppBarDestinations();
      expect(items.map((MyNavigationItem item) => item.viewId), isNot(contains(ViewId.viewRentals)));

      for (final MyNavigationItem item in items) {
        // the rail hides its labels at this width, so tap its icon through the tooltip that names it
        await tester.tap(orientation == Axis.vertical ? find.byTooltip(item.label) : find.byKey(item.key));
        await tester.pump();
      }

      expect(picked, items.map((MyNavigationItem item) => item.viewId).toList());
    });
  }

  testWidgets('the rail highlights the current view by its position among the shown destinations', (
    WidgetTester tester,
  ) async {
    final MyNavigationBar bar = await pumpNavigationBar(
      tester,
      orientation: Axis.vertical,
      selectedView: ViewId.viewStocks,
      picked: <ViewId>[],
    );

    final int? index = tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex;
    expect(bar.getAppBarDestinations()[index!].viewId, ViewId.viewStocks);
  });

  testWidgets('a view without a destination selects nothing on the rail and the first item on the bar', (
    WidgetTester tester,
  ) async {
    final MyNavigationBar rail = await pumpNavigationBar(
      tester,
      orientation: Axis.vertical,
      selectedView: ViewId.viewPolicy,
      picked: <ViewId>[],
    );
    expect(rail.getSelectedIndex(rail.getAppBarDestinations()), isNull);
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, isNull);

    await pumpNavigationBar(tester, orientation: Axis.horizontal, selectedView: ViewId.viewRentals, picked: <ViewId>[]);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
  });

  testWidgets('enabling rentals adds its destination before the AI assistant', (WidgetTester tester) async {
    services.preferenceController.includeRentalManagement = true;
    final List<ViewId> picked = <ViewId>[];
    final MyNavigationBar bar = await pumpNavigationBar(
      tester,
      orientation: Axis.vertical,
      selectedView: ViewId.viewRentals,
      picked: picked,
    );

    final List<ViewId> views = bar.getAppBarDestinations().map((MyNavigationItem item) => item.viewId).toList();
    expect(views.indexOf(ViewId.viewRentals), views.indexOf(ViewId.viewStocks) + 1);
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, views.indexOf(ViewId.viewRentals));
  });
}
