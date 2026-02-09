import 'package:get/get.dart';
import 'package:money/data/collections/data.dart';
import 'package:money/data/entities/investment.dart';
import 'package:money/data/entities/security.dart';
import 'package:money/data/entities/transaction.dart';
import 'package:money/data/models/investment_import_fields.dart';
import 'package:money/data/models/payee.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/views/import/import_investment_panel.dart';
import 'package:money/widgets/dialog.dart';
import 'package:money/widgets/dialog_button.dart';
import 'package:money/widgets/gaps.dart';

void showImportInvestment({InvestmentImportFields? inputData}) {
  inputData ??= InvestmentImportFields(
    account: Data().accounts.getMostRecentlySelectedAccount(),
    date: DateTime.now(),
    investmentType: InvestmentType.buy,
    category: Data().categories.investmentOther,
    symbol: '',
    units: 1,
    amountPerUnit: 0,
    transactionAmount: 0,
    description: '',
  );

  final BuildContext context = Get.context!;
  adaptiveScreenSizeDialog(
    context: context,
    captionForClose: 'Cancel',
    actionButtons: getActionButtons(inputData, context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        gapLarge(),
        Expanded(child: ImportInvestmentPanel(inputFields: inputData)),
      ],
    ),
  );
}

List<Widget> getActionButtons(
  InvestmentImportFields inputData,
  BuildContext context,
) {
  final List<Widget> actionButtons = <Widget>[
    // Button - Import
    DialogActionButton(
      text: 'Add Investment',
      onPressed: () {
        // Import

        final Security security = Data().securities.getOrCreate(
          inputData.symbol,
        );

        // add the Transaction to the Transaction list
        final Payee payee = Data().aliases.findOrCreateNewPayee(
          security.fieldSymbol.value,
          fireNotification: false,
        )!;

        final Transaction newTransaction = Transaction(date: inputData.date);
        newTransaction.fieldAccountId.value = inputData.account.uniqueId;
        newTransaction.fieldPayee.value = payee.uniqueId;
        newTransaction.fieldMemo.value = inputData.description;
        newTransaction.fieldCategoryId.value = inputData.category.uniqueId;
        newTransaction.fieldAmount.value.setAmount(
          inputData.transactionAmount.toDouble(),
        );

        Data().transactions.appendNewMoneyObject(
          newTransaction,
          fireNotification: false,
        );

        // add the Investment transaction to the Investment list
        final Investment investmentToBeAdded = Investment(
          id: -1,
          security: security.fieldId.value,
          units: inputData.units,
          unitPrice: inputData.amountPerUnit,
          investmentType: inputData.investmentType.index,
          tradeType: fromInvestmentType(inputData.investmentType).index,
        );

        Data().investments.appendNewMoneyObject(
          investmentToBeAdded,
          fireNotification: false,
        );
        // Investment are linked to transactions by the uniqueId
        investmentToBeAdded.fieldId.value = newTransaction.uniqueId;

        // update the app
        Data().updateAll();
        Navigator.of(context).pop(false);
      },
    ),
  ];
  return actionButtons;
}
