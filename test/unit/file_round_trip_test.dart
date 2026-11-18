import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/money_data_io_service.dart';
import 'package:sqlite3/sqlite3.dart';

/// Text with every character that has broken serialization before (quotes, separators, newline, unicode).
const String _trickyText = "O'Brien \"q\" , semi; back\\slash\nnew line é 漢字 🙂";

/// Fills the sample's empty tables and optional columns so every column of every table is exercised.
void _populateEveryColumn(String path) {
  final String tricky = _trickyText.replaceAll("'", "''");
  final Database db = sqlite3.open(path);
  db.execute('''
INSERT INTO LoanPayments VALUES (0, 2, '2021-03-04 00:00:00', 123.45, 6.789, '$tricky');
INSERT INTO OnlineAccounts VALUES (0,'OA name','Inst','https://ofx','102','FID1','user','pw','c1','c2','tok','bank','branch','broker','http://logo','QWIN','2500','uid-1','ak','uk','2024-01-02 03:04:05');
INSERT INTO Currencies VALUES (0,'EUR','Euro',1.0845,1.07);
INSERT INTO Aliases VALUES (0,'^AMZN.*',1,3);
INSERT INTO AccountAliases VALUES (0,'xx1234',1,'ACC-1');
INSERT INTO TransactionExtras VALUES (0, 5, 2022, '2022-12-31 00:00:00');
INSERT INTO RentBuildings VALUES (0,'Bldg','1 Main St','2010-05-06 00:00:00',250000.5,50000,400000,'Owner A','Owner B',60,40,'$tricky',3,4,5,6,7,8);
INSERT INTO RentUnits VALUES (0,0,'Unit 1','Renter X','note');
INSERT INTO Splits VALUES (10,0,3,4,-12.34,-1,'split memo',0,NULL);
INSERT INTO Splits VALUES (10,1,5,-1,-7.66,-1,'$tricky',0,'2023-01-01 00:00:00');
UPDATE Transactions SET Memo='$tricky', Number='1001', FITID='FIT-9', OriginalPayee='ORIG PAYEE', ReconciledDate='2020-08-01 00:00:00', SalesTax=1.23, MergeDate='2020-09-09 00:00:00', BudgetBalanceDate='2020-10-10 00:00:00', Status=3, Flags=2 WHERE Id=1;
UPDATE Accounts SET AccountId='ACC-1', OfxAccountId='OFX-1', Description='desc', WebSite='http://bank', LastSync='2024-02-02 00:00:00', SyncGuid='2f1a9c3e-0000-4000-8000-000000000001', LastBalance='2024-03-03 00:00:00', OpeningBalance=10.5, Currency='CAD', ReconcileWarning=3, Flags=1 WHERE Id=1;
UPDATE Securities SET CUSPID='594918104', TAXABLE=1, LastPrice=150.5, PriceDate='2024-04-04 00:00:00' WHERE Id=0;
UPDATE Categories SET Description='cat desc', Color='#FF00FF', Budget=500, Balance=12.5, Frequency=3, TaxRefNum=7 WHERE Id=1;
''');
  db.close();
}

/// Returns the primary key of [row] in [table] (Splits are keyed by transaction and id).
String _keyOf(String table, Row row) => table == 'Splits' ? '${row['Transaction']}/${row['Id']}' : '${row['Id']}';

/// True when two stored values mean the same thing (numbers within rounding, NULL and '' alike for text).
bool _sameValue(Object? expected, Object? actual) {
  if (expected is num && actual is num) {
    return (expected - actual).abs() < 1e-9;
  }
  if ((expected == null || expected == '') && (actual == null || actual == '')) {
    return true;
  }
  return expected == actual;
}

/// Lists every row of [expectedPath] that is missing or different in [actualPath].
///
/// Extra rows are allowed only for the special categories the app creates on demand.
List<String> _differences(String expectedPath, String actualPath) {
  final List<String> differences = <String>[];
  final Database expectedDb = sqlite3.open(expectedPath);
  final Database actualDb = sqlite3.open(actualPath);
  final Iterable<String> tables = expectedDb
      .select("SELECT name FROM sqlite_master WHERE type='table'")
      .map((Row row) => row['name'] as String);
  for (final String table in tables) {
    final Map<String, Row> actualRows = <String, Row>{
      for (final Row row in actualDb.select('SELECT * FROM [$table]')) _keyOf(table, row): row,
    };
    final Map<String, Row> expectedRows = <String, Row>{
      for (final Row row in expectedDb.select('SELECT * FROM [$table]')) _keyOf(table, row): row,
    };
    for (final MapEntry<String, Row> expected in expectedRows.entries) {
      final Row? actual = actualRows[expected.key];
      if (actual == null) {
        differences.add('$table ${expected.key}: missing');
        continue;
      }
      for (final String column in expected.value.keys) {
        if (!_sameValue(expected.value[column], actual[column])) {
          differences.add('$table ${expected.key}.$column: ${expected.value[column]} -> ${actual[column]}');
        }
      }
    }
    for (final String key in actualRows.keys.where((String key) => !expectedRows.containsKey(key))) {
      if (table != 'Categories') {
        differences.add('$table $key: unexpected row');
      }
    }
  }
  expectedDb.close();
  actualDb.close();
  return differences;
}

/// Loads the SQLite file at [path] into the shared [Data] like opening it in the app.
Future<void> _load(String path) async {
  Data().clearExistingData();
  expect(await MoneyDataIO().loadFromSql(Data(), filePath: path, fileBytes: Uint8List(0)), isTrue);
  Data().recalculateBalances();
}

/// All collections that are persisted.
List<MoneyObjects<dynamic>> _collections() => <MoneyObjects<dynamic>>[
  Data().accountAliases,
  Data().accounts,
  Data().aliases,
  Data().categories,
  Data().currencies,
  Data().investments,
  Data().loanPayments,
  Data().onlineAccounts,
  Data().payees,
  Data().rentBuildings,
  Data().rentUnits,
  Data().securities,
  Data().stockSplits,
  Data().transactions,
  Data().transactionExtras,
  Data().splits,
];

/// Flags every live object with [mutation], as if each had been edited or added.
void _markAll(MutationType mutation) {
  for (final MoneyObjects<dynamic> collection in _collections()) {
    for (final DataObject item in collection.iterableList().cast<DataObject>()) {
      item.mutation = mutation;
    }
  }
}

/// Saves pending changes to [path] and returns the error message ('' on success).
Future<String> _save(String path) async {
  String error = '';
  await MoneyDataIO().saveToSql(
    Data(),
    filePath: path,
    onSaveCompleted: (bool success, String message) => error = message,
  );
  return error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory folder;
  late String original;

  setUp(() {
    DataFileController.instance = DataFileController();
    folder = Directory.systemTemp.createTempSync('round_trip');
    original = '${folder.path}/original.mmdb';
    File('integration_test/sample.mmdb').copySync(original);
    _populateEveryColumn(original);
  });

  tearDown(() => folder.deleteSync(recursive: true));

  /// Copies the original file to [name] in the test folder.
  String copyOfOriginal(String name) => File(original).copySync('${folder.path}/$name').path;

  test('updating every row in place, twice, changes no stored value', () async {
    final String file = copyOfOriginal('updated.mmdb');
    for (int cycle = 0; cycle < 2; cycle++) {
      await _load(file);
      _markAll(MutationType.changed);
      expect(await _save(file), isEmpty);
    }
    expect(_differences(original, file), isEmpty);
  });

  test('writing every row into a new file keeps every value', () async {
    await _load(original);
    final String file = '${folder.path}/new.mmdb';
    expect(await MoneyDataIO().writeAllToNewSqlFile(Data(), filePath: file), isNull);
    expect(_differences(original, file), isEmpty);
  });

  test('a CSV backup restores every value', () async {
    await _load(original);
    final List<int> archive = MoneyDataIO().getCsvZipAchieveListOfInt(Data());
    Data().clearExistingData();
    await MoneyDataIO().loadFromZippedCsv(Data(), '', Uint8List.fromList(archive));
    Data().recalculateBalances();
    final String file = '${folder.path}/from_csv.mmdb';
    expect(await MoneyDataIO().writeAllToNewSqlFile(Data(), filePath: file), isNull);
    expect(_differences(original, file), isEmpty);
  });

  test('a deleted row stays deleted in memory after saving', () async {
    final String file = copyOfOriginal('deleted.mmdb');
    await _load(file);
    // an unused payee: deleting one that transactions still use is refused
    final DataObject payee = Data().payees.appendNewMoneyObject(Payee()..fieldName.value = 'Unused');
    expect(await _save(file), isEmpty);
    final int live = Data().payees.iterableList().length;
    Data().deleteItems(<DataObject>[payee]);

    expect(await _save(file), isEmpty);

    expect(Data().payees.iterableList().length, live - 1);
    final Database db = sqlite3.open(file);
    expect(db.select('SELECT COUNT(*) AS c FROM Payees').first['c'], live - 1);
    db.close();
  });

  test('a failing save writes nothing and keeps every change pending', () async {
    final String file = copyOfOriginal('failing.mmdb');
    await _load(file);
    final DataObject account = Data().accounts.iterableList().first as DataObject;
    account.stashValueBeforeEditing();
    account.mutateField('Name', 'Renamed', false);
    account.mutation = MutationType.changed;
    // a second insert of an existing payee id violates the primary key, after the account was written
    (Data().payees.iterableList().first as DataObject).mutation = MutationType.inserted;

    expect((account as Account).fieldName.value, 'Renamed');

    expect(await _save(file), isNotEmpty);

    expect(account.mutation, MutationType.changed);
    expect(_differences(original, file), isEmpty);
  });

  test('saving to an older file adds the columns it lacks and keeps a backup', () async {
    final String file = copyOfOriginal('older.mmdb');
    await _load(file);
    final DataObject currency = Data().currencies.iterableList().first as DataObject;
    currency.mutation = MutationType.changed;

    expect(await _save(file), isEmpty);

    final Database db = sqlite3.open(file);
    expect(db.select('PRAGMA table_info(Currencies)').map((Row row) => row['name']), contains('CultureCode'));
    db.close();
    expect(File('$file.bak').existsSync(), isTrue);
  });
}
