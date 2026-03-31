import 'package:money/data/models/alias_types.dart';
import 'package:money/data/models/data_simulator_constants.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
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
        'Pattern': SharedSimulationStrings.simPatternFoo,
        'Flag': DataSimulatorConstants.defaultFlags,
        'AccountId': 'A12345',
      }),
      fireNotification: false,
    );
    Data().accountAliases.appendNewMoneyObject(
      AccountAlias.fromJson(<String, dynamic>{
        'Pattern': SharedSimulationStrings.simPatternBar,
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
        pattern: SharedSimulationStrings.simPatternAbcUpper,
        flags: AliasType.none.index,
        data: Data(),
      ),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: DataSimulatorConstants.unsetId,
        payeeId: DataSimulatorConstants.payeeIdLotteryWin,
        pattern: SharedSimulationStrings.simPatternAbcLower,
        flags: AliasType.none.index,
        data: Data(),
      ),
      fireNotification: false,
    );
    Data().aliases.appendNewMoneyObject(
      Alias(
        id: DataSimulatorConstants.unsetId,
        payeeId: DataSimulatorConstants.payeeIdBroker,
        pattern: SharedSimulationStrings.simPatternStarbucksRegex,
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
        'Name': SharedSimulationStrings.simCurrencyNameUsa,
        'Symbol': SharedStrings.currencyUsd,
        'CultureCode': 'en-US',
        'Ratio': DataSimulatorConstants.usdRatio,
        'LastRatio': DataSimulatorConstants.usdLastRatio,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': SharedSimulationStrings.simCurrencyNameCanada,
        'Symbol': SharedSimulationStrings.simCurrencyCad,
        'CultureCode': 'en-CA',
        'Ratio': DataSimulatorConstants.cadRatio,
        'LastRatio': DataSimulatorConstants.cadLastRatio,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': SharedSimulationStrings.simCurrencyNameEuro,
        'Symbol': SharedSimulationStrings.simCurrencyEur,
        'CultureCode': 'en-ES',
        'Ratio': DataSimulatorConstants.eurRatio,
        'LastRatio': DataSimulatorConstants.eurLastRatio,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': SharedSimulationStrings.simCurrencyNameUk,
        'Symbol': SharedSimulationStrings.simCurrencyGbp,
        'CultureCode': 'en-GB',
        'Ratio': DataSimulatorConstants.gbpRatio,
        'LastRatio': DataSimulatorConstants.gbpLastRatio,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.unsetId,
        'Name': SharedSimulationStrings.simCurrencyNameJapan,
        'Symbol': SharedSimulationStrings.simCurrencyJpy,
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
      <String, dynamic>{
        'Id': DataSimulatorConstants.payeeIdBurgerKing,
        'Name': SharedSimulationStrings.simPayeeBurgerKingJob,
      },
      <String, dynamic>{'Id': DataSimulatorConstants.payeeIdNasa, 'Name': SharedSimulationStrings.simPayeeNasa},
      <String, dynamic>{
        'Id': DataSimulatorConstants.payeeIdLotteryWin,
        'Name': SharedSimulationStrings.simPayeeLotteryWin,
      },
      <String, dynamic>{'Id': DataSimulatorConstants.payeeIdBroker, 'Name': SharedSimulationStrings.simPayeeBroker},
    ]);
  }

  /// Generates sample events.
  void generateEvents() {
    final dynamic categoryIdForProperties = Data().categories.getByName(SharedSimulationStrings.simCategoryProperties)!;
    final dynamic categoryIdForTravels = Data().categories.getByName(SharedSimulationStrings.simCategoryTravel)!;

    Data().events.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdCondo,
        'Name': SharedSimulationStrings.simEventCondoChicago,
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '1987-03-04',
        'End': '1999-12-04',
        'Memo': SharedSimulationStrings.simEventMemoFirstProperty,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdWedding,
        'Name': SharedSimulationStrings.simEventWedding,
        'Category': categoryIdForTravels.uniqueId,
        'Begin': '1995-06-20',
        'End': '1995-06-30',
        'People': SharedSimulationStrings.simEventPeopleWedding,
        'Memo': SharedSimulationStrings.simEventMemoWedding,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdHome,
        'Name': SharedSimulationStrings.simEventHomeSpringfield,
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '1997-01-04',
        'End': '2016-01-04',
        'Memo': SharedSimulationStrings.simEventMemoFirstHome,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdDivorce,
        'Name': SharedSimulationStrings.simEventDivorce,
        'Begin': '2020-01-01',
        'End': '2020-04-13',
        'People': SharedSimulationStrings.simEventPeopleDivorce,
        'Memo': SharedSimulationStrings.simEventMemoDivorce,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdSoldHouse,
        'Name': SharedSimulationStrings.simEventSoldHouse,
        'Category': categoryIdForProperties.uniqueId,
        'Begin': '2020-03-01',
        'End': '2020-03-05',
        'Memo': SharedSimulationStrings.simEventMemoVegasTrip,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.eventIdVegas,
        'Name': SharedSimulationStrings.simEventVegas,
        'Category': categoryIdForTravels.uniqueId,
        'Begin': '2020-07-01',
        'End': '2020-07-05',
        'People': SharedSimulationStrings.simEventPeopleVegas,
        'Memo': SharedSimulationStrings.simEventMemoVegasBuddies,
      },
    ]);
  }

  /// Generates sample rental buildings and units.
  void generateRentals() {
    Data().rentBuildings.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': DataSimulatorConstants.rentBuildingId,
        'Name': SharedSimulationStrings.simRentalBuildingAirbnb,
        'Address': SharedSimulationStrings.simRentalAddressWashingtonDc,
        'CategoryForIncome': Data().categories
            .getOrCreate(SharedSimulationStrings.simRentalIncome, CategoryType.income)
            .uniqueId,
        'CategoryForInterest': Data().categories
            .getOrCreate(SharedSimulationStrings.simRentalInterest, CategoryType.expense)
            .uniqueId,
        'CategoryForTaxes': Data().categories
            .getOrCreate(SharedSimulationStrings.simRentalTaxes, CategoryType.expense)
            .uniqueId,
        'CategoryForMaintenance': Data().categories
            .getOrCreate(SharedSimulationStrings.simRentalMaintenance, CategoryType.expense)
            .uniqueId,
        'CategoryForManagement': Data().categories
            .getOrCreate(SharedSimulationStrings.simRentalManagement, CategoryType.expense)
            .uniqueId,
      },
    ]);

    Data().rentUnits.loadFromJson(<MyJson>[
      <String, dynamic>{
        'Id': DataSimulatorConstants.rentUnitId,
        'Name': 'roomA',
        'Building': DataSimulatorConstants.rentUnitBuildingId,
        'Renter': SharedSimulationStrings.simRenterBobSmith,
        'Note': SharedSimulationStrings.simRenterNoteOneYear,
      },
      <String, dynamic>{
        'Id': DataSimulatorConstants.rentUnitAlternateId,
        'Name': 'roomB',
        'Building': DataSimulatorConstants.rentUnitBuildingId,
        'Renter': SharedSimulationStrings.simRenterSueRichard,
        'Note': SharedSimulationStrings.simRenterNoteSixMonths,
      },
    ]);
  }
}
