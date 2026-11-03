import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';
import 'package:money/widgets/pickers/picker_account_type.dart';
import 'package:money/widgets/pickers/picker_category_type.dart';
import 'package:money/widgets/pickers/picker_security_type.dart';

/// Pumps [child] inside a minimal app scaffold.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

/// Returns the text currently shown in the picker's edit box.
String _shownText(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  group('pickerEnum', () {
    testWidgets('shows the selected value using toText', (WidgetTester tester) async {
      await _pump(
        tester,
        pickerEnum<InvestmentType>(
          title: 'Type',
          values: InvestmentType.values,
          selected: InvestmentType.buy,
          toText: getInvestmentTypeText,
          onSelected: (InvestmentType _) {},
        ),
      );
      expect(_shownText(tester), 'BUY');
    });

    testWidgets('ignores partial text and selects on an exact match', (WidgetTester tester) async {
      final List<InvestmentType> selected = <InvestmentType>[];
      await _pump(
        tester,
        pickerEnum<InvestmentType>(
          title: 'Type',
          values: InvestmentType.values,
          selected: InvestmentType.buy,
          toText: getInvestmentTypeText,
          onSelected: selected.add,
        ),
      );

      await tester.enterText(find.byType(TextField), 'SE');
      expect(tester.takeException(), isNull);
      expect(selected, isEmpty);

      await tester.enterText(find.byType(TextField), 'SELL');
      expect(selected, <InvestmentType>[InvestmentType.sell]);
    });

    testWidgets('lists the same text it shows and selects from the drop-down', (WidgetTester tester) async {
      final List<InvestmentType> selected = <InvestmentType>[];
      await _pump(
        tester,
        pickerEnum<InvestmentType>(
          title: 'Type',
          values: InvestmentType.values,
          selected: InvestmentType.buy,
          toText: getInvestmentTypeText,
          onSelected: selected.add,
        ),
      );

      await tester.tap(find.byKey(const Key('key_dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('BUY'), findsNWidgets(2)); // edit box and highlighted list item
      await tester.tap(find.text('SELL'));
      await tester.pumpAndSettle();

      expect(selected, <InvestmentType>[InvestmentType.sell]);
      expect(_shownText(tester), 'SELL');
    });
  });

  group('enum pickers ignore partially typed text', () {
    testWidgets('account type', (WidgetTester tester) async {
      final List<AccountType> selected = <AccountType>[];
      await _pump(tester, pickerAccountType(itemSelected: AccountType.checking, onSelected: selected.add));
      await tester.enterText(find.byType(TextField), 'Che');
      expect(tester.takeException(), isNull);
      expect(selected, isEmpty);
    });

    testWidgets('category type', (WidgetTester tester) async {
      final List<CategoryType> selected = <CategoryType>[];
      await _pump(tester, pickerCategoryType(itemSelected: CategoryType.income, onSelected: selected.add));
      await tester.enterText(find.byType(TextField), 'Inc');
      expect(selected, isEmpty);
      await tester.enterText(find.byType(TextField), 'Expense');
      expect(selected, <CategoryType>[CategoryType.expense]);
    });

    testWidgets('security type', (WidgetTester tester) async {
      final List<SecurityType?> selected = <SecurityType?>[];
      await _pump(tester, pickerSecurityType(itemSelected: SecurityType.equity, onSelected: selected.add));
      await tester.enterText(find.byType(TextField), 'eq');
      expect(tester.takeException(), isNull);
      expect(selected, isEmpty);
    });
  });
}
