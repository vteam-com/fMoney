import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/data_mutations_model.dart';

void main() {
  group('DataMutations', () {
    late DataMutations mutations;
    late int notifications;

    setUp(() {
      mutations = DataMutations();
      notifications = 0;
      mutations.addListener(() => notifications++);
    });

    test('increaseNumber counts the changes and notifies once', () {
      mutations.increaseNumber(increaseAdded: 1, increaseChanged: 2, increaseDeleted: 3);

      expect(mutations.numberOfChanges(), 6);
      expect(mutations.isMutated(), isTrue);
      expect(notifications, 1);
    });

    test('reset clears the counters and notifies once', () {
      mutations.increaseNumber(increaseChanged: 1);
      notifications = 0;

      mutations.reset();

      expect(mutations.isMutated(), isFalse);
      expect(notifications, 1);
    });

    test('setLastEditToNow notifies once', () {
      mutations.setLastEditToNow();

      expect(notifications, 1);
    });
  });
}
