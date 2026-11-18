import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/presentation/services/stock_cache_lookup_service.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a refresh caches under the same lowercase key that startup reads', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{settingKeyStockApiKey: 'key'});
    await PreferenceController.to.init();
    addTearDown(() => PreferenceController.instance = null);

    await loadFomBackendAndSaveToCache(Constants.mockStockSymbol.toUpperCase());

    // the startup path, getFromCacheOrBackend, reads 'stock-<lowercase symbol>'
    expect(PreferenceController.to.getString('stock-${Constants.mockStockSymbol}'), isNotEmpty);
  });
}
