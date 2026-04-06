import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/imports/import_data.dart';
import 'package:money/views/imports/import_qfx.dart';

void main() {
  group('QFX:', () {
    test('Read', () {
      final String qfxString = getQfxSample();

      final String ofxString = getStringDelimitedStartEndTokens(
        qfxString,
        '<OFX>',
        '</OFX>',
      );
      expect(ofxString.isEmpty, false);

      final List<ImportEntry> list = getTransactionFromOFX(ofxString);
      expect(list.length, 2);

      expect(list[0].type, 'CREDIT');
      expect(list[0].amount, 2.09);

      expect(list[1].type, 'DEBIT');
      expect(list[1].amount, -2373.71);
      expect(list[1].memo, 'Thank You for Paying');
    });
  });
}

String getQfxSample() {
  return '''
OFXHEADER:100
DATA:OFXSGML
VERSION:102
SECURITY:NONE
ENCODING:USASCII
CHARSET:1252
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE

<OFX>

<SIGNONMSGSRSV1>
<SONRS>
<STATUS>
<CODE>0
<SEVERITY>INFO
</STATUS>
<DTSERVER>20231230224748.000[0:UTC]
<LANGUAGE>ENG
<DTACCTUP>20231230224748.000[0:UTC]
<FI>
<ORG>Bank of America
<FID>1234
</FI>
<INTU.BID>5678
<INTU.USERID>MyName
</SONRS>
</SIGNONMSGSRSV1>
<BANKMSGSRSV1>
<STMTTRNRS>
<TRNUID>0

<STATUS>
<CODE>0
<SEVERITY>INFO
</STATUS>

<STMTRS>
<CURDEF>USD

<BANKACCTFROM>
  <BANKID>89898989
  <ACCTID>000011223344
  <ACCTTYPE>CHECKING
</BANKACCTFROM>

<BANKTRANLIST>

  <DTSTART>2000000000000  
  <DTEND>2333333333333

  <STMTTRN>
    <TRNTYPE>CREDIT    
    <DTPOSTED>20240627000000.000[-7:MST]</DTPOSTED>
    <TRNAMT>2.09
    <FITID>129484.610231229129484.61
    <NAME>Interest Earned
  </STMTTRN>

  <STMTTRN>
    <TRNTYPE>DEBIT
    <DTPOSTED>20231228120000
    <TRNAMT>-2373.71
    <FITID>129482.520231228129482.52
    <NAME>CreditCard AUTOPAY
    <MEMO>Thank You for Paying
  </STMTTRN>

</BANKTRANLIST>

<LEDGERBAL>
<BALAMT>129484.61
<DTASOF>20231230224748
</LEDGERBAL>
</STMTRS>
</STMTTRNRS>
</BANKMSGSRSV1>

</OFX>
''';
}
