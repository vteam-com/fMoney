import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/models/accounts/account.dart';
import 'package:money/views/models/categories/category.dart';
import 'package:money/views/models/data/data.dart';
import 'package:money/views/models/dialog_mutate_money_object.dart';
import 'package:money/widgets/field_filter.dart';
import 'package:money/widgets/field_filters.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuEntry {
  MenuEntry({required this.icon, required this.title, required this.onPressed});

  factory MenuEntry.customAction({
    required final IconData icon,
    required final String text,
    required final void Function() onPressed,
  }) {
    return MenuEntry(icon: icon, title: text, onPressed: onPressed);
  }

  factory MenuEntry.editCategory({
    required final Category category,
    Function? onApplyChange,
  }) {
    return MenuEntry(
      icon: Icons.edit,
      title: 'Edit Category',
      onPressed: () async {
        myShowDialogAndActionsForMoneyObject(
          title: 'Edit "${category.name}"',
          moneyObject: category,
          onApplyChange: () {
            onApplyChange?.call();
          },
        );
      },
    );
  }

  factory MenuEntry.toAccounts({required final int accountId}) {
    return MenuEntry(
      icon: ViewId.viewAccounts.getIconData(),
      title: 'Go to Account',
      onPressed: () {
        // Prepare the Account view to show only the selected account
        final Account? accountInstance = Data().accounts.get(accountId);
        if (accountInstance != null) {
          PreferenceController.to.jumpToView(
            viewId: ViewId.viewAccounts,
            selectedId: accountId,
            textFilter: '',
            columnFilters: null,
          );

          if (accountInstance.isClosed()) {
            // we must show closed account in order to reveal this requested account selection
            if (PreferenceController.to.includeClosedAccounts == false) {
              PreferenceController.to.includeClosedAccounts = true;
            }
          }
        }
      },
    );
  }

  factory MenuEntry.toCategory({required final Category category}) {
    return MenuEntry(
      icon: ViewId.viewCategories.getIconData(),
      title: 'Go to Category',
      onPressed: () {
        // Prepare the Transaction view Filter to show only the selected account
        PreferenceController.to.jumpToView(
          viewId: ViewId.viewCategories,
          selectedId: category.uniqueId,
        );
      },
    );
  }

  factory MenuEntry.toInvestments({
    final String symbol = '',
    final String accountName = '',
  }) {
    final List<FieldFilter> filters = <FieldFilter>[];

    if (symbol.isNotEmpty) {
      filters.add(
        FieldFilter(
          fieldName: Constants.viewStockFieldNameSymbol,
          strings: <String>[symbol],
        ),
      );
    }
    if (accountName.isNotEmpty) {
      filters.add(
        FieldFilter(
          fieldName: Constants.viewStockFieldNameAccount,
          strings: <String>[accountName],
        ),
      );
    }

    // Jump to Stock view
    return MenuEntry(
      icon: ViewId.viewInvestments.getIconData(),
      title: 'Go to Investments',
      onPressed: () {
        PreferenceController.to.jumpToView(
          viewId: ViewId.viewInvestments,
          selectedId: -1,
          textFilter: '',
          columnFilters: FieldFilters(filters),
        );
      },
    );
  }

  factory MenuEntry.toStocks({final String symbol = ''}) {
    late FieldFilter fieldFilterToUse;
    if (symbol.isNotEmpty) {
      fieldFilterToUse = FieldFilter(
        fieldName: Constants.viewStockFieldNameSymbol,
        strings: <String>[symbol],
      );
    }

    // Jump to Stock view
    return MenuEntry(
      icon: ViewId.viewStocks.getIconData(),
      title: 'Go to Stocks',
      onPressed: () {
        PreferenceController.to.jumpToView(
          viewId: ViewId.viewStocks,
          selectedId: -1,
          columnFilters: FieldFilters(<FieldFilter>[fieldFilterToUse]),
          textFilter: '',
        );
      },
    );
  }

  factory MenuEntry.toTransactions({
    required final int transactionId,
    final FieldFilters? filters,
    final String filterText = '',
  }) {
    return MenuEntry(
      icon: ViewId.viewTransactions.getIconData(),
      title: 'Go to Transactions',
      onPressed: () {
        // Prepare the Transaction view Filter to show only the selected account
        PreferenceController.to.jumpToView(
          viewId: ViewId.viewTransactions,
          selectedId: transactionId,
          columnFilters: filters,
          textFilter: filterText,
        );
      },
    );
  }

  factory MenuEntry.toWeb({required final String url}) {
    return MenuEntry(
      icon: Icons.web_asset_outlined,
      title: 'Yahoo finance',
      onPressed: () async {
        final Uri urlWebSite = Uri.parse(url);
        if (await canLaunchUrl(urlWebSite)) {
          await launchUrl(urlWebSite);
        } else {
          SnackBarService.displayError(message: 'Could not launch $urlWebSite');
        }
      },
    );
  }

  final IconData? icon;
  final void Function() onPressed;
  final String title;
}
