import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/data_facade.dart';

import '../helpers/test_fixtures_helper.dart';

void main() {
  setUp(resetTestData);

  tearDown(() => Data().clearExistingData());

  test('edits do not re-report dangling transfers; loading and Rebalance do', () {
    // A transfer to a transaction that doesn't exist is dangling.
    createTestTransaction(createTestAccount(), 'Bank').fieldTransfer.value = 999;
    int reports = 0;
    Data().onDanglingTransfersFound = (int _) => reports++;

    Data().updateAll();
    expect(reports, 0, reason: 'the warning stays up until dismissed, so every edit would queue another one');

    Data().recalculateBalances();
    expect(reports, 1);
  });
}
