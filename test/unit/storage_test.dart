import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/data.dart';

void main() {
  group('DataFromCsv', () {
    group('saveToCsv', () {
      test('saves data to zipped CSV file', () async {
        final List<int> bytes = Data().getCsvZipAchieveListOfInt();

        expect(bytes.isNotEmpty, true);

        final Archive zip = ZipDecoder().decodeBytes(bytes);
        Data().loadFromArchive(zip);
      });
    });
  });
}
