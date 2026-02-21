import 'package:money/helpers/color_helper.dart';
import 'package:money/views/money_object_card.dart';
import 'package:money/views/transactions.dart';

/// A stateless widget for transaction card.
class TransactionCard extends StatelessWidget {
  const TransactionCard({required this.title, super.key, this.transaction});

  final String title;
  final Transaction? transaction;

  @override
  Widget build(BuildContext context) {
    return MoneyObjectCard(title: title, moneyObject: transaction);
  }
}
