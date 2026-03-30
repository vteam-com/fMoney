import 'package:money/data/models/alias_types.dart';
import 'package:money/data/models/data_simulator_constants.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/shared/domain/account_alias.dart';
import 'package:money/shared/domain/alias.dart';
import 'package:money/shared/domain/currency.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/online_account.dart';

/// Generates static reference data entities used by the simulator.
class DataSimulatorReferenceDataDomain {
  /// Generates sample account aliases.
  void generateAccountAliases() {
    Data().accountAliases.appendNewMoneyObject(
      AccountAlias.fromJson(<String, dynamic>{
        'Pattern': '*foo*',
        'Flag': DataSimulatorConstants.defaultFlags,
        'AccountId': 'A12345',
      }),
      fireNotification: false,
    );
    Data().accountAliases.appendNewMoneyObject(
      AccountAlias.fromJson(<String, dynamic>{
        'Pattern': '*bar*',
        'Flag': DataSimulatorConstants.defaultFlags,
        'AccountId': 'B987654',
      }),
      fireNotification: false,
    );
  }

  /// Generates alias patterns for normalization and regex matching.
  void generateAliases() {
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: DataSimulatorConstants.unsetId,
        payeeId: DataSimulatorConstants.payeeIdLotteryWin,
        pattern: 'ABC',
        flags: AliasType.none.index,
        data: Data(),
      ),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: DataSimulatorConstants.unsetId,
        payeeId: DataSimulatorConstants.payeeIdLotteryWin,
        pattern: 'abc',
        flags: AliasType.none.index,
        data: Data(),
      ),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: DataSimulatorConstants.unsetId,
        payeeId: DataSimulatorConstants.payeeIdBroker,
        pattern: '.*starbucks.*',
        flags: AliasType.regex.index,
        data: Data(),
      ),
      fireNotification: false,
    );
  }

  /// Generates sample currencies.
  void generateCurrencies() {
    final List<MyJson> demoCurrencies = <MyJson>[
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': 'USA',
        'Symbol': 'USD',
        'CultureCode': 'en-US',
        'Ratio': DataSimulatorConstants.usdRatio,
        'LastRatio': DataSimulatorConstants.usdLastRatio,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': 'Canada',
        'Symbol': 'CAD',
        'CultureCode': 'en-CA',
        'Ratio': DataSimulatorConstants.cadRatio,
        'LastRatio': DataSimulatorConstants.cadLastRatio,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': 'Euro',
        'Symbol': 'EUR',
        'CultureCode': 'en-ES',
        'Ratio': DataSimulatorConstants.eurRatio,
        'LastRatio': DataSimulatorConstants.eurLastRatio,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': 'UK',
        'Symbol': 'GBP',
        'CultureCode': 'en-GB',
        'Ratio': DataSimulatorConstants.gbpRatio,
        'LastRatio': DataSimulatorConstants.gbpLastRatio,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': 'Japan',
        'Symbol': 'JPY',
        'CultureCode': 'en-JP',
        'Ratio': DataSimulatorConstants.jpyRatio,
        'LastRatio': DataSimulatorConstants.jpyLastRatio,
      },
    ];
    for (final MyJson demoCurrency in demoCurrencies) {
      Data().currencies.appendNewMoneyObject(Currency.fromJson(demoCurrency));
    }
  }

  /// Generates sample online accounts.
  void generateOnlineAccounts() {
    Data().onlineAccounts.loadFromJson(<MyJson>[
      <String, dynamic>{'Id': DataSimulatorConstants.onlineAccountIdFirst, 'Name': 'test1'},
      <String, dynamic>{'Id': DataSimulatorConstants.onlineAccountIdSecond, 'Name': 'test2'},
    ]);
    Data().onlineAccounts.appendNewMoneyObject(
      OnlineAccount.fromJson(<String, dynamic>{'Name': 'test3'}),
      fireNotification: false,
    );
  }

  /// Populates payees with a fixed set of demo entities.
  void generatePayees() {
    Data().payees.loadFromJson(<MyJson>[
      <String, dynamic>{'Id': DataSimulatorConstants.payeeIdBurgerKing, 'Name': 'Job At BurgerKing'},
      <String, dynamic>{'Id': DataSimulatorConstants.payeeIdNasa, 'Name': 'NASA'},
      <String, dynamic>{'Id': DataSimulatorConstants.payeeIdLotteryWin, 'Name': 'Lottery Win'},
      <String, dynamic>{'Id': DataSimulatorConstants.payeeIdBroker, 'Name': 'Broker'},
    ]);
  }

  /// Generates sample events.
  void generateEvents() {
    final dynamic categoryIdForProperties = Data().categories.getByName('Properties')!;
    final dynamic categoryIdForTravels = Data().categories.getByName('Travel')!;

    Data().events.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdCondo,
        'Name': 'Condo in Chicago',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '1987-03-04',
        'End': '1999-12-04',
        'Memo': 'My first property',
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdWedding,
        'Name': 'Wedding and honeymoon',
        'Category': categoryIdForTravels.uniqueId,
        'Begin': '1995-06-20',
        'End': '1995-06-30',
        'People': 'Karen; Bob; Yoko',
        'Memo': 'It was raining, see photos here http://example.com',
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdHome,
        'Name': 'Home in Springfield',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '1997-01-04',
        'End': '2016-01-04',
        'Memo': 'Our first home',
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdDivorce,
        'Name': 'Divorce',
        'Begin': '2020-01-01',
        'End': '2020-04-13',
        'People': 'Karen; Bob',
        'Memo': 'Our friendly divorce',
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdSoldHouse,
        'Name': 'Sold house',
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '2020-03-01',
        'End': '2020-03-05',
        'Memo': 'My trip to Vegas',
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdVegas,
        'Name': 'Vegas',
        'Category': categoryIdForTravels.uniqueId,
        'Begin': '2020-07-01',
        'End': '2020-07-05',
        'People': 'Bob, John, Paul, Ringo',
        'Memo': 'My trip to Vegas with buddies',
      },
    ]);
  }

  /// Generates sample rental buildings and units.
  void generateRentals() {
    Data().rentBuildings.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': DataSimulatorConstants.rentBuildingId,
        'Name': 'AirBnB',
        'Address': 'One Washington DC',
        'CategoryForIncome': Data().categories.getOrCreate('RentalIncome', CategoryType.income).uniqueId,
        'CategoryForInterest': Data().categories.getOrCreate('RentalInterest', CategoryType.expense).uniqueId,
        'CategoryForTaxes': Data().categories.getOrCreate('RentalTaxes', CategoryType.expense).uniqueId,
        'CategoryForMaintenance': Data().categories.getOrCreate('RentalMaintenance', CategoryType.expense).uniqueId,
        'CategoryForManagement': Data().categories.getOrCreate('RentalManagement', CategoryType.expense).uniqueId,
      },
    ]);

    Data().rentUnits.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': DataSimulatorConstants.rentUnitId,
        'Name': 'roomA',
        'Building': DataSimulatorConstants.rentUnitBuildingId,
        'Renter': 'Bob Smith',
        'Note': 'Renting for 1 year',
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.rentUnitAlternateId,
        'Name': 'roomB',
        'Building': DataSimulatorConstants.rentUnitBuildingId,
        'Renter': 'Sue Richard',
        'Note': 'Renting for 6 months',
      },
    ]);
  }
}
