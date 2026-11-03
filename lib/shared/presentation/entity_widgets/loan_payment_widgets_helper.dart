import 'package:money/helpers/currency_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/loan_payment_entity.dart';
import 'package:money/widgets/list/list_item_card.dart';

/// Builds the small-screen card for [loanPayment].
Widget buildLoanPaymentSmallScreenWidget(LoanPayment loanPayment) {
  return MyListItemAsCard(
    leftTopAsString: Account.getName(loanPayment.accountInstance),
    rightTopAsString: getAmountAsStringUsingCurrency(loanPayment.fieldPrincipal),
    rightBottomAsString: getAmountAsStringUsingCurrency(
      loanPayment.fieldInterest,
    ),
  );
}
