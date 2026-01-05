import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:money/import/import_data.dart';
import 'package:money/import/import_qfx.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/data/data_controller.dart';

// Mock classes for dependencies

void main() {
  setUp(() {
    // ignore: unused_local_variable
    final DataController dataController = Get.put(DataController());
  });

  test('importQFX reads file and parses OFX correctly', () async {
    const String fileContent =
        '''<OFX><BANKACCTFROM><BANKID>123456<ACCTID>00001 99-55555<ACCTTYPE>SAVINGS</BANKACCTFROM><BANKTRANLIST><STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20230810<TRNAMT>-50.00<NAME>Sample Transaction</STMTTRN></BANKTRANLIST></OFX>''';
    importQfxFromString(null, fileContent);
  });

  test('OfxBankInfo.fromOfx parses account information correctly', () {
    const String ofxContent = '''<BANKACCTFROM><BANKID>123456<ACCTID>00001 99-55555<ACCTTYPE>SAVINGS</BANKACCTFROM>''';

    final OfxBankInfo bankInfo = OfxBankInfo.fromOfx(ofxContent);

    expect(bankInfo.id, '123456');
    expect(bankInfo.accountId, '00001 99-55555');
    expect(bankInfo.accountType, 'SAVINGS');
  });

  test('getInvestmentCategoryFromOfxType returns correct category ID', () {
    final ImportEntry mockEntry = ImportEntry(
      type: 'CREDIT',
      date: DateTime.now(),
      amount: 100.0,
      name: 'Sample Name',
      fitid: '12345',
      memo: 'Sample Memo',
      number: '123',
    );

    final int categoryId = getInvestmentCategoryFromOfxType(mockEntry);
    expect(categoryId, Data().categories.investmentCredit.fieldId.value);
  });

  test('getTransactionFromOFX parses transactions correctly', () {
    const String ofxContent =
        '''<OFX><BANKTRANLIST><STMTTRN><TRNTYPE>CREDIT<DTPOSTED>20230810<TRNAMT>50.00<NAME>Sample Transaction</STMTTRN></BANKTRANLIST></OFX>''';

    final List<ImportEntry> transactions = getTransactionFromOFX(ofxContent);

    expect(transactions.length, 1);
    expect(transactions.first.type, 'CREDIT');
    expect(transactions.first.amount, 50.0);
  });

  test('findAndGetValueOf returns correct value from line', () {
    const String line = '<ACCTID>00001 99-55555';
    final String value = findAndGetValueOf(line, '<ACCTID>', '');
    expect(value, '00001 99-55555');
  });

  test('getValuePortion extracts value correctly', () {
    const String line = '<ACCTID>00001 99-55555</ACCTID>';
    final String value = getValuePortion(line);
    expect(value, '00001 99-55555');
  });
}
