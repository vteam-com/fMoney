import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/io/money_data_io.dart';

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
