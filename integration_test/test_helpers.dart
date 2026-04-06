// ignore: fcheck_dead_code
import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/panels/side_panel.dart';
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
  final WidgetTester tester,
  final String textToFind, {
  final bool lastOneFound = false,
}) async {
  Finder firstMatchingElement = find.text(textToFind);
  if (lastOneFound) {
    firstMatchingElement = firstMatchingElement.last;
  } else {
    firstMatchingElement = firstMatchingElement.at(_zeroIndex);
  }

  expect(firstMatchingElement, findsOneWidget);
  await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: _shortPumpMs));
}

Finder findByKeyString(final String keyString) {
  final Finder firstMatchingElement = find.byKey(Key(keyString)).at(_zeroIndex);
  expect(firstMatchingElement, findsOneWidget);
  return firstMatchingElement;
}

Future<void> tapOnKeyString(
  final WidgetTester tester,
  final String keyString,
) async {
  final Finder firstMatchingElement = findByKeyString(keyString);
  await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: _shortPumpMs));
}

Future<void> tapOnKey(final WidgetTester tester, final Key key) async {
  final Finder firstMatchingElement = find.byKey(key).at(_zeroIndex);
  expect(firstMatchingElement, findsOneWidget, reason: key.toString());
  await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> tapOnWidgetType(final WidgetTester tester, final Type type) async {
  final Finder firstMatchingElement = find.byElementType(type).at(_zeroIndex);
  expect(firstMatchingElement, findsOneWidget);
  await tester.tap(firstMatchingElement, warnIfMissed: false);
  await tester.myPump();
}

Future<void> tapOnTextFromParentType(
  final WidgetTester tester,
  final Type type,
  final String textToFind,
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

Future<Finder> tapOnFirstRowOfListView(final WidgetTester tester) async {
  return await tapOnFirstRowOfListViewFirstOrLast(tester, true);
}

Future<Finder> tapOnFirstRowOfListViewFirstOrLast(
  final WidgetTester tester,
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
  final WidgetTester tester,
  final String text,
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
  final Finder firstMatchingElement = find.byTooltip('Back');
  expect(firstMatchingElement, findsOneWidget, reason: 'No Back button found');
  await tester.tap(firstMatchingElement);
  await tester.myPump();
}

Future<void> pump(final WidgetTester tester, [int milliseconds = _defaultPumpMs]) async {
  await tester.pumpAndSettle(Duration(milliseconds: milliseconds));
}

extension WidgetTesterExtension on WidgetTester {
  Future<void> myPump([int milliseconds = _defaultMyPumpMs]) async {
    await pump(this, milliseconds);
  }
}

Future<void> switchToSmall(final WidgetTester tester) async {
  ThemeController.to.setAppSizeToSmall();
  await tester.pumpAndSettle();
}

Future<void> switchToMedium(final WidgetTester tester) async {
  ThemeController.to.setAppSizeToMedium();
  await tester.pumpAndSettle();
}

Future<void> switchToLarge(final WidgetTester tester) async {
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

Future<void> inputText(WidgetTester tester, final String textToEnter) async {
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
  final WidgetTester tester,
  final List<String> keys,
) async {
  for (final String key in keys) {
    await tapOnKeyString(tester, key);
  }
}

Future<void> inputTextToTextFieldWithThisLabel(
  WidgetTester tester,
  final String labelToFind,
  final String textToInput,
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

Finder findTextFieldByLabel(final String labelToFind) {
  final Finder textFieldFinder = find.byWidgetPredicate(
    (Widget widget) => widget is TextField && widget.decoration?.labelText == labelToFind,
  );
  return textFieldFinder;
}
