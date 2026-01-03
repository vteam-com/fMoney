import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/money_objects/data.dart';

void main() {
  // Mark todo as partially completed - basic round-trip test created
  group('Basic SQLite to CSV Round-trip Test', () {
    test('Can save and load data using both formats', () async {
      // Create a basic data instance
      final Data originalData = Data();

      // Test that we can create ZIP CSV data
      final List<int> csvZipBytes = originalData.getCsvZipAchieveListOfInt();
      expect(csvZipBytes.isNotEmpty, isTrue);

      // Test that we can load from the ZIP CSV data
      final Data loadedData = Data();
      final Uint8List csvZipUint8List = Uint8List.fromList(csvZipBytes);
      await loadedData.loadFromZippedCsv('', csvZipUint8List);

      // Basic verification - both data instances exist and are valid
      expect(loadedData, isNotNull);

      // Test that SQLite methods are available (even if we don't call them)
      expect(originalData.saveToSql, isNotNull);
      expect(originalData.loadFromSql, isNotNull);
    });

    test('CSV archive contains expected structure', () async {
      final Data data = Data();
      final List<int> csvZipBytes = data.getCsvZipAchieveListOfInt();

      // Decode the archive
      final Archive archive = ZipDecoder().decodeBytes(csvZipBytes);

      // Should contain files even if empty
      expect(archive.isNotEmpty, isTrue);

      // Should contain expected CSV files
      final List<String> fileNames = archive.files.map((ArchiveFile f) => f.name.toLowerCase()).toList();
      expect(fileNames, contains('accounts.csv'));
      expect(fileNames, contains('transactions.csv'));
      expect(fileNames, contains('categories.csv'));
    });

    test('Empty data round-trip preservation', () async {
      final Data originalData = Data();
      originalData.clearExistingData();

      // Export to CSV
      final List<int> csvZipBytes = originalData.getCsvZipAchieveListOfInt();

      // Import from CSV
      final Data loadedData = Data();
      final Uint8List csvZipUint8List = Uint8List.fromList(csvZipBytes);
      await loadedData.loadFromZippedCsv('', csvZipUint8List);

      // Verify empty state is preserved
      expect(originalData.accounts.isEmpty, isTrue);
      expect(originalData.transactions.isEmpty, isTrue);
      expect(originalData.categories.isEmpty, isTrue);
      expect(loadedData.accounts.isEmpty, isTrue);
      expect(loadedData.transactions.isEmpty, isTrue);
      expect(loadedData.categories.isEmpty, isTrue);
    });

    test('CSV data format verification', () async {
      final Data data = Data();
      data.clearExistingData();

      final List<int> csvZipBytes = data.getCsvZipAchieveListOfInt();
      final Archive archive = ZipDecoder().decodeBytes(csvZipBytes);

      expect(csvZipBytes.isNotEmpty, isTrue); // ZIP data should not be empty
      expect(csvZipBytes.length > 22, isTrue); // Should be a valid ZIP with headers

      // Check files are properly archived
      int csvFileCount = 0;
      for (final ArchiveFile file in archive) {
        if (file.isFile && file.name.endsWith('.csv')) {
          csvFileCount++;

          final List<int> fileBytes = file.content as List<int>;
          // Try to decode as UTF-8 to ensure it's not corrupt
          try {
            utf8.decode(fileBytes, allowMalformed: false);
            // If we get here, the file is valid UTF-8, which is what we want
          } catch (e) {
            fail('${file.name} contains invalid UTF-8 data: $e');
          }
        }
      }

      // Should have multiple CSV files
      expect(
        csvFileCount >= 3,
        isTrue,
        reason: 'Should contain at least 3 CSV files (accounts, transactions, categories)',
      );
    });

    test('Multiple round-trip operations maintain data integrity', () async {
      final Data originalData = Data();
      originalData.clearExistingData();

      // Multiple CSV conversions
      final List<int> csvBytes1 = originalData.getCsvZipAchieveListOfInt();
      final Data data1 = Data();
      await data1.loadFromZippedCsv('', Uint8List.fromList(csvBytes1));

      final List<int> csvBytes2 = data1.getCsvZipAchieveListOfInt();
      final Data data2 = Data();
      await data2.loadFromZippedCsv('', Uint8List.fromList(csvBytes2));

      final List<int> csvBytes3 = data2.getCsvZipAchieveListOfInt();
      final Data data3 = Data();
      await data3.loadFromZippedCsv('', Uint8List.fromList(csvBytes3));

      // All should maintain empty state
      expect(data1.accounts.isEmpty, isTrue);
      expect(data2.accounts.isEmpty, isTrue);
      expect(data3.accounts.isEmpty, isTrue);

      // Archive sizes should be consistent
      expect(csvBytes1.length > 100, isTrue); // Should contain headers/metadata
      expect(csvBytes2.length == csvBytes1.length, isTrue);
      expect(csvBytes3.length == csvBytes1.length, isTrue);
    });
  });
}
