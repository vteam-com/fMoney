import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/reconcile_service.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// Footer shown under an account's transactions while it is being reconciled: the statement
/// date and balance, the cleared balance and the difference left, with Cancel and Finish.
///
/// Finish only appears once the difference is zero. The totals refresh on every data change,
/// so toggling a transaction's status updates them immediately.
class ReconcileBar extends StatelessWidget {
  /// Creates the footer for [session].
  const ReconcileBar({
    super.key,
    required this.session,
    required this.onCancel,
    required this.onFinish,
  });

  /// Called when the user leaves reconcile mode; cleared transactions stay cleared.
  final VoidCallback onCancel;

  /// Called when the user finishes a balanced reconciliation.
  final VoidCallback onFinish;

  /// The reconciliation shown.
  final ReconcileService session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DataFileController.to.trackMutations,
      builder: (BuildContext context, Widget? _) {
        return Padding(
          padding: const EdgeInsets.all(SizeForPadding.normal),
          child: Wrap(
            spacing: SizeForPadding.huge,
            runSpacing: SizeForPadding.normal,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(AppL10n.tr(AppTranslationKeys.reconcileInstructions), style: getTextTheme(context).bodySmall),
              _buildValue(AppL10n.tr(AppTranslationKeys.statementDate), Text(dateToString(session.statementDate))),
              _buildAmount(AppL10n.tr(AppTranslationKeys.aiStatementBalance), session.statementBalance),
              _buildAmount(AppL10n.tr(AppTranslationKeys.clearedBalance), session.clearedBalance),
              _buildAmount(AppL10n.tr(AppTranslationKeys.difference), session.difference),
              DialogActionButton(text: AppL10n.tr(AppTranslationKeys.cancel), onPressed: onCancel),
              if (session.isBalanced)
                DialogActionButton(text: AppL10n.tr(AppTranslationKeys.finish), onPressed: onFinish),
            ],
          ),
        );
      },
    );
  }

  /// Builds a [caption] followed by [amount] in the account's currency.
  Widget _buildAmount(String caption, double amount) {
    return _buildValue(
      caption,
      WidgetFromData(
        amountModel: AmountModel(
          amount: amount,
          iso4217: session.account.getAccountCurrencyAsText(),
          showCurrency: false,
          autoColor: true,
        ),
      ),
    );
  }

  /// Builds a [caption] followed by its [value].
  Widget _buildValue(String caption, Widget value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[Text(caption), gapMedium(), value],
    );
  }
}
