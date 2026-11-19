import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/widgets/suggestion_approval_widget.dart';
import 'package:money/views/imports/formats/csv_import_view.dart';
import 'package:money/views/imports/formats/qfx_import_view.dart';
import 'package:money/views/imports/formats/qif_import_view.dart';
import 'package:money/views/imports/formats/xlsx_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';
import 'package:money/views/imports/shared/import_duplicate_helper.dart';
import 'package:money/views/imports/shared/import_number_input_helper.dart';
import 'package:money/widgets/columns/value_parser.dart';
import 'package:money/widgets/columns/value_quality.dart';
import 'package:money/widgets/dialogs/csv_column_mapper_dialog.dart';

/// Creates and appends an account fixture.
Account _createAccount(String name) {
  final Account account = Account();
  account.fieldName.value = name;
  account.fieldCurrency.value = 'USD';
  return Data().accounts.appendNewMoneyObject(account, fireNotification: false) as Account;
}

/// Creates and appends a transaction fixture in [account].
Transaction _createTransaction({
  required Account account,
  required double amount,
  required DateTime date,
  String fitid = '',
}) {
  final Transaction transaction = Transaction(date: date);
  transaction.fieldAccountId.value = account.uniqueId;
  transaction.fieldAmount.value.setAmount(amount);
  transaction.fieldFitid.value = fitid;
  Data().appendNewTransaction(transaction, fireNotification: false);
  return transaction;
}

/// Builds an imported preview row for [date] (`yyyy-MM-dd`) and [amount].
ValuesQuality _importRow(String date, String amount, {String fitid = ''}) {
  return ValuesQuality(
    date: ValueQuality(date, dateFormat: 'yyyy-MM-dd'),
    description: const ValueQuality('Coffee'),
    amount: ValueQuality(amount),
    fitid: fitid,
  );
}

void main() {
  setUp(() {
    DataFileController.instance = DataFileController();
    Data().clearExistingData();
  });

  group('QIF dates', () {
    test('parseQifDate reads apostrophe years and padded parts', () {
      expect(parseQifDate("1/ 5'24"), DateTime(2024, 1, 5));
      expect(parseQifDate("12/31'99"), DateTime(1999, 12, 31));
      expect(parseQifDate("01/30'2000"), DateTime(2000, 1, 30));
      expect(parseQifDate('01/30/2023'), DateTime(2023, 1, 30));
      expect(parseQifDate('not a date'), isNull);
    });

    test('loadQIF skips an unreadable date instead of aborting', () {
      final ImportData data = loadQIF(<String>['!Type:Bank', 'Dgarbage', 'T-1.00', '^', "D1/ 5'24", 'T-2.00', '^']);
      expect(data.entries.length, 1);
      expect(data.entries.first.date, DateTime(2024, 1, 5));
      expect(data.diagnostics.skippedRows, 1);
    });

    test('loadQIF records each account that holds transactions', () {
      final ImportData data = loadQIF(<String>[
        '!Account',
        'NChecking',
        'TBank',
        '^',
        '!Type:Bank',
        'D01/02/2024',
        'T-1.00',
        '^',
        '!Account',
        'NSavings',
        'TBank',
        '^',
        '!Type:Bank',
        'D01/03/2024',
        'T5.00',
        '^',
      ]);
      expect(data.entries.length, 2);
      expect(data.sourceAccounts, <String>{'Checking', 'Savings'});
    });
  });

  group('OFX dates', () {
    test('parseOfxDate accepts 8 and 14 digit forms with suffixes', () {
      expect(parseOfxDate('20240103'), DateTime(2024, 1, 3));
      expect(parseOfxDate('20240103120000.000[-5:EST]'), DateTime(2024, 1, 3, 12));
      expect(parseOfxDate('20240231'), isNull);
      expect(parseOfxDate(''), isNull);
    });

    test('parseQFXTransactions skips rows without a readable date', () {
      final ImportDiagnostics diagnostics = ImportDiagnostics();
      final List<ImportEntry> entries = parseQFXTransactions(<String>[
        '<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20240103<TRNAMT>-5.00<NAME>Ok</STMTTRN>',
        '<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>bad<TRNAMT>-6.00<NAME>Bad</STMTTRN>',
      ], diagnostics: diagnostics);
      expect(entries.length, 1);
      expect(entries.first.date, DateTime(2024, 1, 3));
      expect(diagnostics.skippedRows, 1);
    });
  });

  group('Imported investments', () {
    test('a sell exported with a negative quantity stores positive units', () {
      final ImportEntry entry = ImportEntry(
        type: '',
        date: DateTime(2024),
        amount: 100,
        name: 'Sale',
        fitid: '',
        stockSymbol: 'ABC',
        stockQuantity: -10,
        stockPrice: 10,
      );
      final Investment investment = buildInvestmentFromImportEntry(entry)!;
      expect(investment.fieldUnits.value, 10);
      expect(investment.fieldInvestmentType.value, InvestmentType.sell.index);
    });

    test('appendInvestmentForTransaction keys the investment by its transaction id', () {
      final Account account = _createAccount('Brokerage');
      _createTransaction(account: account, amount: -1, date: DateTime(2024));
      // The second transaction's id differs from the next free investment id.
      final Transaction transaction = _createTransaction(account: account, amount: -50, date: DateTime(2024));
      expect(transaction.uniqueId, isNot(Data().investments.getNextId()));
      final Investment investment = Investment(
        id: -1,
        security: 1,
        unitPrice: 5,
        units: 10,
        investmentType: InvestmentType.buy.index,
        tradeType: 0,
      );

      appendInvestmentForTransaction(investment, transaction);

      expect(investment.uniqueId, transaction.uniqueId);
      expect(Data().investments.get(transaction.uniqueId), same(investment));
      expect(investment.mutation, MutationType.inserted);
    });
  });

  group('Column mapping', () {
    test('Balance is never picked as the Amount column', () {
      expect(
        findBestMatchingColumnIndex(
          headers: <String>['Date', 'Description', 'Amount', 'Balance'],
          patterns: csvAmountColumnPatterns,
        ),
        2,
      );
      expect(
        findBestMatchingColumnIndex(headers: <String>['Date', 'Balance'], patterns: csvAmountColumnPatterns),
        -1,
      );
    });

    test('earlier patterns win over later ones', () {
      expect(
        findBestMatchingColumnIndex(headers: <String>['Price', 'Amount'], patterns: csvAmountColumnPatterns),
        1,
      );
    });

    test('Portuguese headers picked by the XLSX row picker are mapped, Saldo is never the Amount', () {
      const List<String> headers = <String>['Saldo', 'Data', 'Detalhes', 'Valor'];
      expect(findBestMatchingColumnIndex(headers: headers, patterns: csvDateColumnPatterns), 1);
      expect(findBestMatchingColumnIndex(headers: headers, patterns: csvDescriptionColumnPatterns), 2);
      expect(findBestMatchingColumnIndex(headers: headers, patterns: csvAmountColumnPatterns), 3);
      expect(findBestMatchingColumnIndex(headers: <String>['Fecha', 'Saldo'], patterns: csvAmountColumnPatterns), -1);
    });

    test('duplicate headers resolve to their own column', () {
      final List<String> headers = <String>['Date', 'Description', 'Amount', 'Amount'];
      expect(buildUniqueColumnIds(headers), <String>['Date', 'Description', 'Amount', 'Amount (2)']);
      expect(indexOfMappedColumn(headers, 'Amount (2)'), 3);
      expect(indexOfMappedColumn(headers, 'Amount'), 2);

      final ImportData data = loadCSV(
        headers,
        <List<String>>[
          <String>['2024-01-15', 'Coffee', '1.00', '4.50'],
        ],
        <String, String>{'date': 'Date', 'description': 'Description', 'amount': 'Amount (2)'},
      );
      expect(data.entries.single.amount, 4.50);
    });
  });

  group('XLSX', () {
    test('cells are placed by reference and shared strings only for t="s"', () {
      const String sheet =
          '<sheetData><row r="1"><c r="A1" t="s"><v>0</v></c><c r="C1"><v>100</v></c></row>'
          '<row r="2"><c r="B2" t="inlineStr"><is><t>Inline</t></is></c><c r="D2"/></row></sheetData>';
      final List<List<String>> rows = parseXlsxSheetRows(sheet, <String>['Shared']);
      expect(rows[0], <String>['Shared', '', '100']);
      expect(rows[1], <String>['', 'Inline', '', '']);
    });

    test('rich-text shared strings keep one entry per item', () {
      expect(
        parseXlsxSharedStrings('<sst><si><r><t>Hel</t></r><r><t>lo</t></r></si><si><t>World</t></si></sst>'),
        <String>['Hello', 'World'],
      );
    });

    test('xlsxColumnLettersToIndex handles multi-letter columns', () {
      expect(xlsxColumnLettersToIndex('A'), 0);
      expect(xlsxColumnLettersToIndex('Z'), 25);
      expect(xlsxColumnLettersToIndex('AA'), 26);
    });

    test('only the date column converts Excel serial numbers', () {
      final ImportData data = loadXLSX(
        <String>['Date', 'Description', 'Amount', 'Quantity'],
        <List<String>>[
          <String>['45306', 'Trade', '25000', '3'],
          <String>['bad', 'Skipped', '1', ''],
        ],
        <String, String>{'date': 'Date', 'description': 'Description', 'amount': 'Amount', 'quantity': 'Quantity'},
      );
      expect(data.entries.single.date, DateTime(2024, 1, 15));
      expect(data.entries.single.amount, 25000);
      expect(data.entries.single.stockQuantity, 3);
      expect(data.fileType, 'XLSX');
      expect(data.diagnostics.skippedRows, 1);
    });
  });

  group('Duplicate detection', () {
    late Account account;

    setUp(() {
      account = _createAccount('Checking');
    });

    test('one existing transaction matches only one imported row', () {
      _createTransaction(account: account, amount: -4.5, date: DateTime(2024, 1, 10));
      final List<ValuesQuality> rows = <ValuesQuality>[
        _importRow('2024-01-10', '-4.50'),
        _importRow('2024-01-10', '-4.50'),
      ];

      markExistingImportValues(accountId: account.uniqueId, values: rows);

      expect(rows.where((ValuesQuality row) => row.exist).length, 1);
    });

    test('deleted transactions are not duplicates', () {
      final Transaction deleted = _createTransaction(account: account, amount: -4.5, date: DateTime(2024, 1, 10));
      Data().transactions.deleteItem(deleted);
      final List<ValuesQuality> rows = <ValuesQuality>[_importRow('2024-01-10', '-4.50')];

      markExistingImportValues(accountId: account.uniqueId, values: rows);

      expect(rows.single.exist, isFalse);
    });

    test('FITID decides over date and amount', () {
      _createTransaction(account: account, amount: -4.5, date: DateTime(2024, 1, 10), fitid: 'A1');
      final List<ValuesQuality> rows = <ValuesQuality>[
        // Same FITID, different date: duplicate.
        _importRow('2024-01-12', '-4.50', fitid: 'A1'),
        // Same date and amount, different FITID: a new transaction.
        _importRow('2024-01-10', '-4.50', fitid: 'B2'),
      ];

      markExistingImportValues(accountId: account.uniqueId, values: rows);

      expect(rows[0].exist, isTrue);
      expect(rows[1].exist, isFalse);
    });

    test('generated CSV ids do not block date and amount matching', () {
      _createTransaction(account: account, amount: -4.5, date: DateTime(2024, 1, 10), fitid: 'csv_row_1_123');
      final List<ValuesQuality> rows = <ValuesQuality>[_importRow('2024-01-10', '-4.50', fitid: 'BANK-9')];

      markExistingImportValues(accountId: account.uniqueId, values: rows);

      expect(rows.single.exist, isTrue);
    });

    test('findExistingTransaction keeps deleted rows by default', () {
      final Transaction deleted = _createTransaction(account: account, amount: -1, date: DateTime(2024, 2, 1));
      Data().transactions.deleteItem(deleted);
      final DateRange day = DateRange(min: DateTime(2024, 2, 1), max: DateTime(2024, 2, 1, 23, 59));
      expect(
        Data().transactions.findExistingTransaction(accountId: account.uniqueId, dateRange: day, amount: -1),
        same(deleted),
      );
      expect(
        Data().transactions.findExistingTransaction(
          accountId: account.uniqueId,
          dateRange: day,
          amount: -1,
          includeDeleted: false,
        ),
        isNull,
      );
    });
  });

  group('Text import', () {
    test('header and unreadable rows are not importable', () {
      final ValuesParser parser = ValuesParser(dateFormat: 'yyyy-MM-dd', currency: 'USD');
      parser.convertInputTextToTransactionList(
        null,
        'Date; Description; Amount\n2024-01-10; Coffee; -4.50\n2024-01-11; ; -3.00\nbad; Tea; 2.00',
      );
      expect(parser.lines.length, 4);
      expect(parser.onlyNewTransactions.single.description.asString(), 'Coffee');
    });
  });

  group('Manual import numbers', () {
    test('parseImportNumberInput reads grouped numbers and rejects text', () {
      expect(parseImportNumberInput('1,200'), 1200);
      expect(parseImportNumberInput('1.234,56'), 1234.56);
      expect(parseImportNumberInput('abc').isNaN, isTrue);
    });
  });

  group('AI suggestion splits', () {
    test('nextSplitIdForTransaction uses the highest id of that transaction', () {
      /// Builds a split fixture with [id] for [transactionId].
      TransactionSplit split(int id, int transactionId) => TransactionSplit(
        id: id,
        transactionId: transactionId,
        categoryId: -1,
        payeeId: -1,
        amount: 0,
        transferId: -1,
        memo: '',
        flags: 0,
        budgetBalanceDate: null,
        data: Data(),
      );

      expect(nextSplitIdForTransaction(<TransactionSplit>[], 7), 0);
      expect(nextSplitIdForTransaction(<TransactionSplit>[split(0, 7), split(4, 7), split(9, 8)], 7), 5);
    });
  });
}
