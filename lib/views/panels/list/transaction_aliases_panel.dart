import 'package:material_ui/material_ui.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/presentation/dialogs/mutate_money_object_dialog.dart';
import 'package:money/shared/presentation/helpers/alias_apply_helper.dart';
import 'package:money/widgets/pure/center_message_widget.dart';

/// Side-panel list of the aliases related to the selected [transactions]; tapping one edits it, and
/// Apply re-assigns the transactions it then matches.
class TransactionAliasesPanel extends StatefulWidget {
  const TransactionAliasesPanel({required this.transactions, super.key});

  /// The selected transactions.
  final List<Transaction> transactions;

  @override
  State<TransactionAliasesPanel> createState() => _TransactionAliasesPanelState();
}

class _TransactionAliasesPanelState extends State<TransactionAliasesPanel> {
  @override
  Widget build(BuildContext context) {
    final List<Alias> aliases = Data().aliases.relatedTo(widget.transactions);
    if (aliases.isEmpty) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noMatchingAliases));
    }
    return ListView(
      children: <Widget>[
        for (final Alias alias in aliases)
          ListTile(
            dense: true,
            title: Text(alias.fieldPattern.value),
            subtitle: Text(Data().getPayeeName(alias.fieldPayeeId.value)),
            trailing: Text(getAliasTypeAsString(alias.type)),
            onTap: () => myShowDialogAndActionsForMoneyObject(
              title: AppL10n.tr(AppTranslationKeys.alias),
              moneyObject: alias,
              onApplyChange: () {
                setState(() {});
                applyAliasesAndReport(<Alias>[alias]);
              },
            ),
          ),
      ],
    );
  }
}
