import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/components/box_with_scrolling_content_widget.dart';
import 'package:money/widgets/components/label_and_amount_widget.dart';
import 'package:money/widgets/components/rental_pnl_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

const double _headerPadding = 30.0;
const double _percentageScale = 100.0;

/// A stateless widget for rental pn l card.
class RentalPnLCard extends StatelessWidget {
  const RentalPnLCard({required this.pnl, super.key, this.customTitle});

  final String? customTitle;
  final RentalPnL pnl;

  @override
  Widget build(BuildContext context) {
    return BoxWithScrollingContent(
      children: <Widget>[
        Row(
          children: <Widget>[
            gap(_headerPadding),
            Expanded(
              child: Text(
                customTitle == null ? pnl.date.year.toString() : customTitle!,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              key: const Key('key_card_copy_to_clipboard'),
              onPressed: () {
                copyToClipboardAndInformUser(context, pnl.toString());
              },
              iconSize: SizeForIcon.small,
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
        LabelAndAmount(
          caption: AppL10n.tr(AppTranslationKeys.incomeLabel),
          amount: pnl.income,
          currencyIso4217: pnl.currency,
        ),
        gapLarge(),
        LabelAndAmount(
          caption: AppL10n.tr(AppTranslationKeys.expenseLabel),
          amount: pnl.expenses,
          currencyIso4217: pnl.currency,
        ),
        gapMedium(),
        LabelAndAmount(
          caption: AppL10n.tr(AppTranslationKeys.interest),
          amount: pnl.expenseInterest,
          currencyIso4217: pnl.currency,
          small: true,
        ),
        LabelAndAmount(
          caption: AppL10n.tr(AppTranslationKeys.maintenance),
          amount: pnl.expenseMaintenance,
          currencyIso4217: pnl.currency,
          small: true,
        ),
        LabelAndAmount(
          caption: AppL10n.tr(AppTranslationKeys.management),
          amount: pnl.expenseManagement,
          currencyIso4217: pnl.currency,
          small: true,
        ),
        LabelAndAmount(
          caption: AppL10n.tr(AppTranslationKeys.repairs),
          amount: pnl.expenseRepairs,
          currencyIso4217: pnl.currency,
          small: true,
        ),
        LabelAndAmount(
          caption: AppL10n.tr(AppTranslationKeys.taxes),
          amount: pnl.expenseTaxes,
          currencyIso4217: pnl.currency,
          small: true,
        ),
        gapLarge(),
        LabelAndAmount(
          caption: AppL10n.tr(AppTranslationKeys.profit),
          amount: pnl.profit,
          currencyIso4217: pnl.currency,
        ),
        gapMedium(),
        distribution(),
      ],
    );
  }

  /// Builds a distribution list widget showing percentage allocations.
  Widget distribution() {
    final List<Widget> widgets = <Widget>[];

    pnl.distributions.forEach((String name, double percentage) {
      if (name.isNotEmpty) {
        widgets.add(
          LabelAndAmount(
            caption: '  $name',
            amount: pnl.profit * (percentage / _percentageScale),
            currencyIso4217: pnl.currency,
            small: true,
          ),
        );
      }
    });

    return Column(children: widgets);
  }
}
