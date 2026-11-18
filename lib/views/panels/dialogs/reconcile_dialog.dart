import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/reconcile_service.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pickers/edit_box_date_picker_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/my_text_input_widget.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _labelWidth = 160.0;

/// Shows the dialog that starts reconciling [account]; [onStart] receives the new
/// reconciliation once the user has entered the statement date and ending balance.
void showReconcileDialog({
  required BuildContext context,
  required Account account,
  required DataAbstract data,
  required void Function(ReconcileService session) onStart,
}) {
  adaptiveScreenSizeDialog(
    context: context,
    title: AppL10n.tr(AppTranslationKeys.reconcileWithStatement),
    captionForClose: null, // the dialog has its own Cancel button
    child: ReconcileDialog(account: account, data: data, onStart: onStart),
  );
}

/// Form asking for the statement date and ending balance before reconciling [account].
class ReconcileDialog extends StatefulWidget {
  /// Creates the form for [account]; [onStart] receives the reconciliation when the user starts it.
  const ReconcileDialog({
    super.key,
    required this.account,
    required this.data,
    required this.onStart,
  });

  /// The account to reconcile.
  final Account account;

  /// Data access used to compute the reconciled balance and to apply the reconciliation.
  final DataAbstract data;

  /// Called with the new reconciliation when the user presses Start.
  final void Function(ReconcileService session) onStart;

  @override
  State<ReconcileDialog> createState() => _ReconcileDialogState();
}

class _ReconcileDialogState extends State<ReconcileDialog> {
  double? _statementBalance;
  DateTime? _statementDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final DateTime? lastReconciled = widget.account.fieldLastBalance.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.account.fieldName.value, style: getTextTheme(context).titleMedium),
        gapLarge(),
        _buildRow(
          AppL10n.tr(AppTranslationKeys.lastReconciled),
          Text(lastReconciled == null ? AppL10n.tr(AppTranslationKeys.never) : dateToString(lastReconciled)),
        ),
        _buildRow(
          AppL10n.tr(AppTranslationKeys.reconciledBalance),
          WidgetFromData(
            amountModel: AmountModel(
              amount: ReconcileService.reconciledBalanceOf(widget.account, widget.data),
              iso4217: widget.account.getAccountCurrencyAsText(),
            ),
          ),
        ),
        gapLarge(),
        _buildRow(
          AppL10n.tr(AppTranslationKeys.statementDate),
          PickerEditBoxDate(
            initialValue: dateToString(_statementDate),
            onChanged: (String text) => setState(() => _statementDate = attemptToGetDateFromText(text)),
          ),
        ),
        gapLarge(),
        _buildRow(
          AppL10n.tr(AppTranslationKeys.aiStatementBalance),
          MyTextInput(
            onChanged: (String text) => setState(() => _statementBalance = parseAmountFlexible(text)),
          ),
        ),
        gapLarge(),
        dialogActionButtons(<Widget>[
          DialogActionButton(
            text: AppL10n.tr(AppTranslationKeys.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          if (_statementDate != null && _statementBalance != null)
            DialogActionButton(
              text: AppL10n.tr(AppTranslationKeys.start),
              onPressed: _start,
            ),
        ]),
      ],
    );
  }

  /// Builds one form row: [label] on the left, [value] filling the rest.
  Widget _buildRow(String label, Widget value) {
    return Row(
      children: <Widget>[
        SizedBox(width: _labelWidth, child: Text(label)),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: value),
        ),
      ],
    );
  }

  /// Hands the new reconciliation to [ReconcileDialog.onStart] and closes the dialog.
  void _start() {
    widget.onStart(
      ReconcileService(
        account: widget.account,
        data: widget.data,
        statementDate: _statementDate!,
        statementBalance: _statementBalance!,
      ),
    );
    Navigator.pop(context);
  }
}
