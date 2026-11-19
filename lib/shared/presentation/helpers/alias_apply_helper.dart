import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/helpers/transactions_updated_snack_bar_helper.dart';

/// Points the transactions each of [aliases] matches at its payee, refreshes the views when any
/// changed, and tells the user how many did.
void applyAliasesAndReport(Iterable<Alias> aliases) {
  int count = 0;
  for (final Alias alias in aliases) {
    count += Data().applyAlias(alias);
  }
  if (count > 0) {
    Data().updateAll();
  }
  displayTransactionsUpdated(count);
}
