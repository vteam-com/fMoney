import 'package:flutter/material.dart';
import 'package:money/data/models/field_filter.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/account.dart';
import 'package:money/shared/domain/category.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/presentation/dialog_mutate_money_object.dart';
import 'package:money/widgets/components/popup_menu_icon_button.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/snack_bar.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';
import 'package:url_launcher/url_launcher.dart';

/// Represents menu entry.
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
      title: '${AppL10n.tr(AppTranslationKeys.edit)} ${AppL10n.tr(AppTranslationKeys.category)}',
      onPressed: () async {
        myShowDialogAndActionsForMoneyObject(
          title: '${AppL10n.tr(AppTranslationKeys.edit)} ${category.name}',
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
      title: AppL10n.tr(AppTranslationKeys.navAccounts),
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
      title: AppL10n.tr(AppTranslationKeys.navCategories),
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
      title: AppL10n.tr(AppTranslationKeys.navInvestments),
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
      title: AppL10n.tr(AppTranslationKeys.navStocks),
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
      title: AppL10n.tr(AppTranslationKeys.navTransactions),
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
      title: SharedStrings.labelYahooFinance,
      onPressed: () async {
        final Uri urlWebSite = Uri.parse(url);
        if (await canLaunchUrl(urlWebSite)) {
          await launchUrl(urlWebSite);
        } else {
          SnackBarService.displayError(message: '${SharedStrings.messageCouldNotLaunch}$urlWebSite');
        }
      },
    );
  }

  final IconData? icon;
  final void Function() onPressed;
  final String title;
}

/// Builds a menu button with a dropdown of menu items.
Widget buildMenuButton(
  final BuildContext context,
  final List<MenuEntry> menuItems, {
  IconData icon = Icons.more_horiz,
  String tooltip = SharedStrings.labelSwitchView,
}) {
  final List<PopupMenuItem<int>> list = <PopupMenuItem<int>>[];
  for (int i = 0; i < menuItems.length; i++) {
    list.add(
      PopupMenuItem<int>(
        value: i,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Icon(menuItems[i].icon),
            gapLarge(),
            Expanded(child: Text(menuItems[i].title)),
          ],
        ),
      ),
    );
  }
  return myPopupMenuIconButton(
    context: context,
    icon: icon,
    tooltip: tooltip,
    list: list,
    onSelected: (final int index) {
      menuItems[index].onPressed();
    },
  );
}

/// Builds a button for jumping between different views.
Widget buildJumpToButton(
  final BuildContext context,
  final List<MenuEntry> listOfViewToJumpTo,
) {
  return buildMenuButton(
    context,
    listOfViewToJumpTo,
    icon: Icons.open_in_new_outlined,
    tooltip: SharedStrings.labelSwitchView,
  );
}
