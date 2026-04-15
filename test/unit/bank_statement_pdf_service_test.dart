import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/home/ai/bank_statement_pdf_service.dart';

void main() {
  group('BankStatementPdfService', () {
    test('detects EUR when statement text contains spaced currency token', () {
      const BankStatementPdfService service = BankStatementPdfService();

      final BankStatementParseResult result = service.parseExtractedText(
        rawText: '''
PREVIOUS BALANCE IN EUR 433.584,71
03-02-25 492 03-02-25 DEBIT /ENDESA ENERGIA 32,67
03-02-25 824 01-02-25 VISA CLASSIC BILL 411,14
03-02-25 825 01-02-25 VISA CLASSIC BILL 3.092,78
''',
        filePath: '/tmp/statement.pdf',
      );

      expect(result.detectedCurrencyCode, 'EUR');
    });

    test('parses debit-column euro statement rows with ambiguous dates as MM-DD', () {
      const BankStatementPdfService service = BankStatementPdfService();

      final BankStatementParseResult result = service.parseExtractedText(
        rawText: '''
Date Ref Value Dat. Description Debit (-)
03-02-25 492 03-02-25 DEBIT /ENDESA ENERGIA 32,67
03-02-25 824 01-02-25 VISA CLASSIC BILL 411,14
03-02-25 825 01-02-25 VISA CLASSIC BILL 3.092,78
04-02-25 159 04-02-25 DEBIT /O2 MOVIL 2,58
17-02-25 937 17-02-25 DEBIT /MEO ENERGIA 43,64
''',
        filePath: '/tmp/statement.pdf',
      );

      expect(result.transactions.length, 5);
      // Ambiguous dates (both parts <= 12): first=month, second=day.
      expect(result.transactions[0].date, DateTime(2025, 3, 2));
      expect(result.transactions[0].amount, '32,67');
      expect(result.transactions[1].amount, '411,14');
      expect(result.transactions[2].amount, '3.092,78');
      expect(result.transactions[3].date, DateTime(2025, 4, 2));
      expect(result.transactions[3].amount, '2,58');
      // 17 > 12, so parser flips to DD-MM.
      expect(result.transactions[4].date, DateTime(2025, 2, 17));
      expect(result.transactions[4].amount, '43,64');
    });

    test('parses statement rows with ref and secondary value dates', () {
      const BankStatementPdfService service = BankStatementPdfService();

      final BankStatementParseResult result = service.parseExtractedText(
        rawText: '''
Date Ref Value Dat. Description Debit (-)
02-10-24 824 01-10-24 VISA CLASSIC BILL 1.874,05
02-10-24 825 01-10-24 VISA CLASSIC BILL 1.114,51
02-10-24 492 02-10-24 DEBIT /ENDESA ENERGIA 15,954
04-10-24 159 04-10-24 DEBIT /O2 FIBRA 65,004
08-10-24 937 08-10-24 DEBIT /MEO, SA 74,974
''',
        filePath: '/tmp/statement.pdf',
      );

      expect(result.transactions.length, 5);
      // Ambiguous dates: first=month, second=day.
      expect(result.transactions[0].date, DateTime(2024, 2, 10));
      expect(result.transactions[0].amount, '1.874,05');
      expect(result.transactions[1].date, DateTime(2024, 2, 10));
      expect(result.transactions[1].amount, '1.114,51');
      expect(result.transactions[2].date, DateTime(2024, 2, 10));
      expect(result.transactions[2].amount, '15,954');
      expect(result.transactions[3].date, DateTime(2024, 4, 10));
      expect(result.transactions[3].amount, '65,004');
      expect(result.transactions[4].date, DateTime(2024, 8, 10));
      expect(result.transactions[4].amount, '74,974');
    });

    group('dot-separated dates', () {
      test('YYYY-MM-DD with spaced thousands not matched by fallback regex', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Date Ref Value Dat. Description Debit (-)
2024-10-02 824 2024-10-01 VISA CLASSIC BILL 1 874,05
2024-10-02 825 2024-10-01 VISA CLASSIC BILL 1 114,51
''',
          filePath: '/tmp/statement.pdf',
        );

        // YYYY-MM-DD format not matched by regex (requires 1-2 digit date parts).
        expect(result.transactions, isEmpty);
      });

      test('year-first dates not matched by fallback regex', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Date Description Amount
2024-10-02 ENDESA ENERGIA 15,954
2024-10-04 O2 FIBRA 65,004
2024-10-08 MEO, SA 74,974
''',
          filePath: '/tmp/statement.pdf',
        );

        expect(result.transactions, isEmpty);
      });

      test('dot-separated dates not matched by fallback regex', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Date Description Amount
03.02.2025 ENDESA ENERGIA 32,67
04.02.2025 O2 MOVIL 2,58
17.02.2025 MEO ENERGIA 43,64
''',
          filePath: '/tmp/statement.pdf',
        );

        // Dot separator not supported by fallback regex (only / and -).
        expect(result.transactions, isEmpty);
      });

      test('dot-separated dates with 2-digit year not matched by fallback regex', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Date Description Amount
03.02.25 ENDESA ENERGIA 32,67
''',
          filePath: '/tmp/statement.pdf',
        );

        expect(result.transactions, isEmpty);
      });
    });

    group('euro symbol amounts', () {
      test('preserves raw amount token including stray OCR digits', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Date Description Debit (-)
04-10-24 GYM MEMBERSHIP 15,954
08-10-24 MOBILE BILL 65,004
18-10-24 STREAMING 43,164
''',
          filePath: '/tmp/statement.pdf',
        );

        expect(result.transactions.length, 3);
        // Amount is now the raw token string.
        expect(result.transactions[0].amount, '15,954');
        expect(result.transactions[1].amount, '65,004');
        expect(result.transactions[2].amount, '43,164');
      });

      test('euro symbol prefix not matched by fallback regex', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Date Description Debit (-)
03-02-25 ENDESA ENERGIA €32,67
04-02-25 O2 MOVIL €2,58
''',
          filePath: '/tmp/statement.pdf',
        );

        // € not supported by fallback amount regex (only \$).
        expect(result.transactions, isEmpty);
      });

      test('parses amounts with dollar symbol prefix in debit column', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Date Description Debit (-)
02-03-25 ELECTRIC COMPANY \$100.50
''',
          filePath: '/tmp/statement.pdf',
        );

        expect(result.transactions.length, 1);
        // Amount is now the raw token string.
        expect(result.transactions[0].amount, '\$100.50');
      });

      test('extracts euro amounts from balance lines', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Opening Balance: €1,234.56
Ending Balance: €2,345.67
''',
          filePath: '/tmp/statement.pdf',
        );

        expect(result.statementBalance, 2345.67);
      });

      test('euro symbol with leading negative sign not matched by fallback regex', () {
        const BankStatementPdfService service = BankStatementPdfService();

        final BankStatementParseResult result = service.parseExtractedText(
          rawText: '''
Date Description Amount
03-02-25 ENDESA ENERGIA -€32,67
04-02-25 O2 MOVIL -€2,58
''',
          filePath: '/tmp/statement.pdf',
        );

        // -€ prefix not supported by fallback amount regex.
        expect(result.transactions, isEmpty);
      });
    });

    test('rejects Bankinter header metadata lines as transactions', () {
      const BankStatementPdfService service = BankStatementPdfService();

      final BankStatementParseResult result = service.parseExtractedText(
        rawText: '''
Banca PersonalR.M. MADRID, T. 1.857, F. 220, H. 9.643, N.I.F. €0281.573.602.024
MONTHLY STATEMENT (October2024 )NANCY BOUCHARDCL RUIZ DE ALARCON 27 3 C28014MadridMADRID
0056Dear Ms.BOUCHARDThe following is the statement of your positions on31th October2024
01.DEPOSITS AT SIGHTCurrencyInitial balanceFinal balanceCUENTA CORRIENTE ORO
____-__-__ (0 days) ____-__-__Total €0281.573.602.024.110.489.600.000
''',
        filePath: '/tmp/statement.pdf',
      );

      expect(result.transactions, isEmpty);
    });
  });
}
