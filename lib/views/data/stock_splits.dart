import 'package:collection/collection.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/views/data/security.dart';
import 'package:money/views/data/stock_split.dart';
import 'package:money/widgets/money_objects.dart';

// Exports
export 'package:money/views/data/stock_split.dart';

class StockSplits extends MoneyObjects<StockSplit> {
  StockSplits() {
    collectionName = 'Stock Splits';
  }

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(StockSplit.fromJson(row));
    }
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  void clearSplitForSecurity(final int securityId) {
    final Iterable<StockSplit> listOfSplitsFound = iterableList().where(
      (StockSplit split) => split.fieldSecurity.value == securityId,
    );
    for (final StockSplit ss in listOfSplitsFound) {
      deleteItem(ss);
    }
  }

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
