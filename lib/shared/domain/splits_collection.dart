import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';

/// Represents splits.
class Splits extends MoneyObjects<TransactionSplit> {
  Splits() {
    collectionName = SharedDomainStrings.domainString127;
  }
  late DataAbstract data;

  @override
  void appendMoneyObject(DataObject moneyObject) {
    super.appendMoneyObject(moneyObject);

    // Attach the split back to the their  container Transaction
    final TransactionSplit splitAdded = moneyObject as TransactionSplit;
    final dynamic containerTransaction = data.getTransaction(
      splitAdded.fieldTransactionId.value,
    );
    if (containerTransaction != null) {
      (containerTransaction as Transaction).splits.add(moneyObject);
    }
  }

  @override
  List<TransactionSplit> loadFromJson(List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(
        TransactionSplit(
          // 0
          transactionId: row.getInt(SharedDomainStrings.domainString141, -1),
          // 1
          id: row.getInt(SharedDomainStrings.domainString057, -1),
          // 2
          categoryId: row.getInt(SharedDomainStrings.domainString029, -1),
          // 3
          payeeId: row.getInt(SharedDomainStrings.domainString105, -1),
          // 4
          amount: row.getDouble(SharedDomainStrings.domainString017),
          // 5
          transferId: row.getInt(SharedDomainStrings.domainString144, -1),
          // 6
          memo: row.getString(SharedDomainStrings.domainString086),
          // 7
          flags: row.getInt(SharedDomainStrings.domainString055),
          // 8
          budgetBalanceDate: row.getDate(SharedDomainStrings.domainString025),
          data: data,
        ),
      );
    }
    return iterableList().toList();
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }
}
