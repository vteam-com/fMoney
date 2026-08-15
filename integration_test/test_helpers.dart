// ignore: fcheck_dead_code
import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/views/panels/layout/side_panel_widget.dart';
import 'package:money/widgets/list/list_item.dart';
import 'package:money/widgets/state/theme_controller.dart';

const int _zeroIndex = 0;
const double _zeroDouble = 0.0;
const int _shortPumpMs = 500;
const int _defaultPumpMs = 300;
const int _defaultMyPumpMs = 100;
const int _minFinds = 1;
const double _scrollDeltaY = -100.0;

Future<void> tapOnText(
  WidgetTester tester,
  String textToFind, {
  bool lastOneFound = false,
}) async {
  Finder firstMatchingElement = find.text(textToFind);
  expect(
    firstMatchingElement,
    findsAny,
    reason: 'tapOnText "$textToFind"',
  );

  if (lastOneFound) {
    firstMatchingElement = firstMatchingElement.last;
  } else {
    firstMatchingElement = firstMatchingElement.at(_zeroIndex);
  }

  expect(firstMatchingElement, findsOneWidget);
  await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: _shortPumpMs));
}

Finder findByKeyString(String keyString) {
  final Finder firstMatchingElement = find.byKey(Key(keyString)).at(_zeroIndex);
  expect(firstMatchingElement, findsOneWidget);
  return firstMatchingElement;
}

Future<void> tapOnKeyString(
  WidgetTester tester,
  String keyString,
) async {
  final Finder firstMatchingElement = findByKeyString(keyString);
  await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: _shortPumpMs));
}

Future<void> tapOnKey(WidgetTester tester, Key key) async {
  final Finder firstMatchingElement = find.byKey(key).at(_zeroIndex);
  expect(firstMatchingElement, findsOneWidget, reason: key.toString());
  await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> tapOnWidgetType(WidgetTester tester, Type type) async {
  final Finder firstMatchingElement = find.byElementType(type).at(_zeroIndex);
  expect(firstMatchingElement, findsOneWidget);
  await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.myPump();
}

Future<void> tapOnTextFromParentType(
  WidgetTester tester,
  Type type,
  String textToFind,
) async {
  Finder firstMatchingElement = find.descendant(
    of: find.byType(type),
    matching: find.text(textToFind),
  );
  expect(
    firstMatchingElement,
    findsAny,
    reason: 'tapOnTextFromParentType "$textToFind"',
  );

  firstMatchingElement = firstMatchingElement.at(_zeroIndex);

  expect(firstMatchingElement, findsOneWidget);
  // await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.tapAt(
    tester.getTopLeft(firstMatchingElement, warnIfMissed: false),
  );
  await tester.myPump();
}

Future<Finder> tapOnFirstRowOfListView(WidgetTester tester) async {
  return await tapOnFirstRowOfListViewFirstOrLast(tester, true);
}

Future<Finder> tapOnFirstRowOfListViewFirstOrLast(
  WidgetTester tester,
  bool first,
) async {
  Finder firstMatchingElement = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Row),
  );
  expect(firstMatchingElement, findsAny);

  firstMatchingElement = first ? firstMatchingElement.first : firstMatchingElement.last;

  expect(firstMatchingElement, findsOneWidget);
  // for row we tap on the top left side to avoid any active widget in the row like "Split", "Accept suggestion"
  await tester.tapAt(
    tester.getTopLeft(firstMatchingElement, warnIfMissed: false),
  );
  await tester.myPump();
  return firstMatchingElement;
}

Future<Finder> selectListViewItemByText(
  WidgetTester tester,
  String text,
) async {
  final Finder listFinder = find.byType(ListView);
  final Finder itemFinder = find.text(text);

  await tester.dragUntilVisible(
    itemFinder, // What you're looking for
    listFinder, // ListView finder
    const Offset(_zeroDouble, _scrollDeltaY), // Scroll down by 100 pixels
  );

  Finder firstMatchingElement = find.descendant(
    of: find.byType(ListView),
    matching: find.text(text),
  );
  expect(firstMatchingElement, findsAny);

  firstMatchingElement = firstMatchingElement.at(_zeroIndex);

  expect(firstMatchingElement, findsOneWidget);
  // for row we tap on the top left side to avoid any active widget in the row like "Split", "Accept suggestion"
  await tester.tapAt(
    tester.getTopLeft(firstMatchingElement, warnIfMissed: false),
  );
  await tester.myPump();
  return firstMatchingElement;
}

Future<void> tapBackButton(WidgetTester tester) async {
  Finder firstMatchingElement = find.byTooltip('Back');
  if (firstMatchingElement.evaluate().isEmpty) {
    firstMatchingElement = find.byType(BackButton);
  }
  if (firstMatchingElement.evaluate().isEmpty) {
    firstMatchingElement = find.text('Close');
  }
  if (firstMatchingElement.evaluate().isEmpty) {
    firstMatchingElement = find.text('Cancel');
  }
  if (firstMatchingElement.evaluate().isEmpty) {
    final NavigatorState? navigator = AppRouter.navigator;
    if (navigator != null && navigator.canPop()) {
      await navigator.maybePop();
      await tester.myPump();
      return;
    }
  }
  expect(
    firstMatchingElement,
    findsAtLeast(_minFinds),
    reason: 'No Back/Close/Cancel control found',
  );

  firstMatchingElement = firstMatchingElement.first;
  await tester.tap(firstMatchingElement);
  await tester.myPump();
}

Future<void> pump(WidgetTester tester, [int milliseconds = _defaultPumpMs]) async {
  await tester.pumpAndSettle(Duration(milliseconds: milliseconds));
}

extension WidgetTesterExtension on WidgetTester {
  Future<void> myPump([int milliseconds = _defaultMyPumpMs]) async {
    await pump(this, milliseconds);
  }
}

Future<void> switchToSmall(WidgetTester tester) async {
  ThemeController.to.setAppSizeToSmall();
  await tester.pumpAndSettle();
}

Future<void> switchToMedium(WidgetTester tester) async {
  ThemeController.to.setAppSizeToMedium();
  await tester.pumpAndSettle();
}

Future<void> switchToLarge(WidgetTester tester) async {
  ThemeController.to.setAppSizeToLarge();
  await tester.pumpAndSettle();
}

// Select first element of the Side-Panel-Transaction-List
Future<void> selectFirstItemOfSidePanelTransactionList(
  WidgetTester tester,
) async {
  final Finder element = await getFirstItemOfList(tester, SidePanel);
  await tester.tap(element, warnIfMissed: false);
  await tester.myPump();
}

// Long Press first element of the Side-Panel-Transaction-List
Future<void> longPressFirstItemOfSidePanelTransactionLIst(
  WidgetTester tester,
) async {
  await longPressFirstItemOfListView(tester, SidePanel);
}

// Long Press first element of the Side-Panel-Transaction-List
Future<void> longPressFirstItemOfListView(
  WidgetTester tester,
  Type typeParentListContainer,
) async {
  final Finder firstMatchingElement = await getFirstItemOfList(
    tester,
    typeParentListContainer,
  );
  expect(firstMatchingElement, findsAtLeast(_minFinds));
  await tester.longPress(firstMatchingElement, warnIfMissed: true);
}

Future<Finder> getFirstItemOfList(
  WidgetTester tester,
  Type typeParentListContainer,
) async {
  // Select first element of the Side-Panel-Transaction-List
  Finder firstMatchingElement = find.descendant(
    of: find.byType(typeParentListContainer),
    matching: find.byType(MyListItem),
  );
  expect(firstMatchingElement, findsAtLeast(_minFinds));

  firstMatchingElement = firstMatchingElement.at(_zeroIndex);

  expect(firstMatchingElement, findsOneWidget);
  return firstMatchingElement;
}

Future<void> inputText(WidgetTester tester, String textToEnter) async {
  final Finder filterInput = find.byType(TextField).at(_zeroIndex);
  await inputTextToElement(tester, filterInput, textToEnter);
}

Future<void> inputTextToElement(
  WidgetTester tester,
  Finder filterInput,
  String textToEnter,
) async {
  await tester.enterText(filterInput, textToEnter);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.myPump();
}

Future<void> inputTextToElementByKey(
  WidgetTester tester,
  Key keyToElement,
  String textToEnter,
) async {
  final Finder firstMatchingElement = find.byKey(keyToElement).at(_zeroIndex);
  await tester.enterText(firstMatchingElement, textToEnter);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.myPump();
}

Future<void> tapAllToggleButtons(
  WidgetTester tester,
  List<String> keys,
) async {
  for (final String key in keys) {
    await tapOnKeyString(tester, key);
  }
}

Future<void> inputTextToTextFieldWithThisLabel(
  WidgetTester tester,
  String labelToFind,
  String textToInput,
) async {
  final Finder textFieldFinder = findTextFieldByLabel(
    labelToFind,
  ).at(_zeroIndex);
  expect(
    textFieldFinder,
    findsOneWidget,
    reason: 'searching for label $labelToFind',
  );
  await inputTextToElement(tester, textFieldFinder, textToInput);
}

Finder findTextFieldByLabel(String labelToFind) {
  final Finder textFieldFinder = find.byWidgetPredicate(
    (Widget widget) => widget is TextField && widget.decoration?.labelText == labelToFind,
  );
  return textFieldFinder;
}
