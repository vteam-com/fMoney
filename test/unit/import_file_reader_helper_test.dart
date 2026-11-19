import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/imports/formats/csv_import_view.dart';
import 'package:money/views/imports/formats/qif_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';
import 'package:money/views/imports/shared/import_file_reader_helper.dart';

void main() {
  group('decodeImportFileBytes', () {
    test('decodes UTF-8 text', () {
      expect(decodeImportFileBytes(utf8.encode('Café crème')), 'Café crème');
    });

    test('falls back to Latin-1 when the bytes are not valid UTF-8', () {
      expect(decodeImportFileBytes(latin1.encode('Café crème')), 'Café crème');
    });
  });

  group('readImportFileAsText', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('import_file_reader_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('reads a Latin-1 CSV export that a UTF-8 only read rejects', () async {
      final File file = File('${tempDir.path}/latin1.csv');
      await file.writeAsBytes(latin1.encode('Date,Description,Amount\n2024-01-15,Café Crème,-5.00\n'));

      final String? text = await readImportFileAsText(file.path);

      expect(text, isNotNull);
      expect(parseCsvContent(text!).dataRows.single[1], 'Café Crème');
    });

    test('reads a Latin-1 QIF export', () async {
      final File file = File('${tempDir.path}/latin1.qif');
      await file.writeAsBytes(latin1.encode('!Type:Bank\r\nD01/15/2024\r\nT-5.00\r\nPCafé Crème\r\n^\r\n'));

      final String? text = await readImportFileAsText(file.path);
      final ImportData importData = loadQIF(LineSplitter.split(text!).toList());

      expect(importData.entries.single.name, 'Café Crème');
    });
  });
}
