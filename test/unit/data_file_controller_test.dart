import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a new "Untitled" file has no real path to save to', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferenceController.to.init();
    addTearDown(() => PreferenceController.instance = null);
    final DataFileController controller = DataFileController();

    expect(controller.hasRealFilePath, isFalse);

    controller.setCurrentFileName('/data/mymoney.mmdb');
    expect(controller.hasRealFilePath, isTrue);
  });
}
