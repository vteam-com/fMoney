import 'package:collection/collection.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/data_abstract.dart';
import 'package:money/shared/domain/money_objects.dart';
import 'package:money/shared/domain/security.dart';
import 'package:money/shared/domain/stock_split.dart';

/// Represents stock splits.
class StockSplits extends MoneyObjects<StockSplit> {
  StockSplits() {
    collectionName = SharedDomainStrings.domainString129;
  }

  late DataAbstract data;

  @override
  StockSplit instanceFromJson(final MyJson json) {
    return StockSplit.fromJson(json, data);
  }

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(instanceFromJson(row));
    }
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  /// Returns all stock splits for a security, sorted by date.
  List<StockSplit> getStockSplitsForSecurity(final Security s) {
    final List<StockSplit> list = <StockSplit>[];
    for (StockSplit split in iterableList()) {
      if (!s.isDeleted && split.fieldSecurity.value == s.uniqueId) {
        list.add(split);
      }
    }
    list.sort((final StockSplit a, final StockSplit b) {
      return a.fieldDate.value!.compareTo(b.fieldDate.value!);
    });

    return list;
  }

  /// Only add, no removal of existing splits
  void setStockSplits(final int securityId, final List<StockSplit> values) {
    final List<StockSplit> listOfSplitsFound = iterableList()
        .where(
          (StockSplit split) => split.fieldSecurity.value == securityId,
        )
        .toList();
    for (final StockSplit ss in values) {
      final StockSplit? foundMatch = listOfSplitsFound.firstWhereOrNull(
        (StockSplit existingSplit) => isSameDateWithoutTime(
          existingSplit.fieldDate.value,
          ss.fieldDate.value,
        ),
      );
      if (foundMatch == null) {
        appendNewMoneyObject(ss, fireNotification: false);
      }
    }
  }
}
