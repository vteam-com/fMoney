import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the saved text zoom is restored at launch', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{settingKeyTextScale: 1.5});
    final PreferenceController controller = PreferenceController();

    await controller.init();

    expect(controller.textScale, 1.5);
  });

  test('a stale saved view index falls back to the default instead of throwing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      settingKeyCashflowView: 99,
      settingKeyBudgetViewAsIncomes: -1,
    });
    final PreferenceController controller = PreferenceController();

    await controller.init();

    expect(controller.cashflowViewAs, CashflowViewAs.sankey);
    expect(controller.budgetViewAsForIncomes, BudgetViewAs.list);
  });
}
