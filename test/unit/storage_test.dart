import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/services/money_data_io_service.dart';

void main() {
  group('DataFromCsv', () {
    group('saveToCsv', () {
      test('saves data to zipped CSV file', () async {
        final List<int> bytes = MoneyDataIO().getCsvZipAchieveListOfInt(Data());

        expect(bytes.isNotEmpty, true);

        final Archive zip = ZipDecoder().decodeBytes(bytes);
        MoneyDataIO().loadFromArchive(Data(), zip);
      });
    });
  });
}
