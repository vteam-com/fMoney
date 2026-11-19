import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/mergeable_item_interface.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/presentation/dialogs/merge_payees_dialog.dart' as merge_payees_dialog;
import 'package:money/shared/presentation/entity_widgets/merge_payee_provider_interface.dart';

/// Implementation of MergePayeeProvider using the merge payees dialog's showMergePayee function.
class DefaultMergePayeeProvider implements MergePayeeProvider {
  @override
  void showMergePayee<T extends MergeableItem>(
    BuildContext context,
    Payee payee,
    Iterable<T> transactions,
    DataAbstract data,
  ) {
    // Prefixed: an unprefixed call resolves to this very method and recurses forever.
    merge_payees_dialog.showMergePayee<T>(
      context,
      payee,
      transactions,
      data,
    );
  }
}
