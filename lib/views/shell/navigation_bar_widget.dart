import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/views/shell/navigation_item_model.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';

// Exports
export 'package:material_ui/material_ui.dart';
export 'package:money/widgets/pure/scale_down_widget.dart';

const double _navRailMinWidth = 50.0;
const double _navBarHeight = 52.0;

/// A stateless widget for my navigation bar.
class MyNavigationBar extends StatelessWidget {
  const MyNavigationBar({
    super.key,
    required this.orientation,
    required this.selectedView,
    required this.onSelected,
  });

  final void Function(ViewId) onSelected;
  final Axis orientation;

  /// The view shown now; it may have no destination (for example Policy, or Rentals when disabled).
  final ViewId selectedView;

  @override
  Widget build(BuildContext context) {
    final List<MyNavigationItem> items = getAppBarDestinations();
    final int? selectedIndex = getSelectedIndex(items);
    if (orientation == Axis.vertical) {
      final List<NavigationRailDestination> destinations = geMenuItemsFortNavRail(items);
      return Container(
        color: getColorTheme(context).secondaryContainer,
        child: SingleChildScrollView(
          child: IntrinsicHeight(
            child: NavigationRail(
              minWidth: _navRailMinWidth,
              destinations: destinations,
              selectedIndex: selectedIndex,
              useIndicator: true,
              labelType: context.isWidthLarge ? NavigationRailLabelType.all : NavigationRailLabelType.none,
              indicatorColor: getColorTheme(context).onSecondary,
              backgroundColor: getColorTheme(context).secondaryContainer,
              onDestinationSelected: (int index) {
                onSelected(items[index].viewId);
              },
            ),
          ),
        ),
      );
    }
    return NavigationBar(
      // the bar cannot show "no selection", so a view without a destination highlights the first one
      selectedIndex: selectedIndex ?? 0,
      onDestinationSelected: (int index) {
        onSelected(items[index].viewId);
      },
      destinations: geMenuItemsFortNavBar(items),
      height: _navBarHeight,
      indicatorColor: getColorTheme(context).onSecondary,
      backgroundColor: getColorTheme(context).secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
    );
  }

  /// Returns bottom navigation bar destinations for [items].
  List<NavigationDestination> geMenuItemsFortNavBar(List<MyNavigationItem> items) {
    return items
        .map(
          (MyNavigationItem item) => NavigationDestination(
            key: item.key,
            label: item.label,
            tooltip: AppL10n.tr(AppTranslationKeys.navShowLabel, params: <String, String>{'label': item.label}),
            icon: item.icon,
            selectedIcon: item.icon,
          ),
        )
        .toList();
  }

  /// Returns navigation rail destinations for [items].
  List<NavigationRailDestination> geMenuItemsFortNavRail(List<MyNavigationItem> items) {
    return items
        .map(
          (MyNavigationItem item) => NavigationRailDestination(
            icon: Tooltip(message: item.label, child: item.icon),
            selectedIcon: Tooltip(message: item.label, child: item.icon),
            label: Text(key: item.key, item.label),
          ),
        )
        .toList();
  }

  /// Returns list of navigation items for app bar destinations.
  List<MyNavigationItem> getAppBarDestinations() {
    final List<MyNavigationItem> appBarDestinations = <MyNavigationItem>[
      MyNavigationItem(
        viewId: ViewId.viewCashFlow,
        label: AppL10n.tr(AppTranslationKeys.navCashflow),
        tooltip: AppL10n.tr(AppTranslationKeys.navCashflowTooltip),
        icon: ViewId.viewCashFlow.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewEvents,
        label: AppL10n.tr(AppTranslationKeys.navEvents),
        tooltip: AppL10n.tr(AppTranslationKeys.navEventsTooltip),
        icon: ViewId.viewEvents.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewAccounts,
        label: AppL10n.tr(AppTranslationKeys.navAccounts),
        tooltip: AppL10n.tr(AppTranslationKeys.navAccountsTooltip),
        icon: ViewId.viewAccounts.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewCategories,
        label: AppL10n.tr(AppTranslationKeys.navCategories),
        tooltip: AppL10n.tr(AppTranslationKeys.navCategoriesTooltip),
        icon: ViewId.viewCategories.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewPayees,
        label: AppL10n.tr(AppTranslationKeys.navPayees),
        tooltip: AppL10n.tr(AppTranslationKeys.navPayeesTooltip),
        icon: ViewId.viewPayees.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewAliases,
        label: AppL10n.tr(AppTranslationKeys.navAliases),
        tooltip: AppL10n.tr(AppTranslationKeys.navAliasesTooltip),
        icon: ViewId.viewAliases.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewTransactions,
        label: AppL10n.tr(AppTranslationKeys.navTransactions),
        tooltip: AppL10n.tr(AppTranslationKeys.navTransactionsTooltip),
        icon: ViewId.viewTransactions.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewTransfers,
        label: AppL10n.tr(AppTranslationKeys.navTransfers),
        tooltip: AppL10n.tr(AppTranslationKeys.navTransfersTooltip),
        icon: ViewId.viewTransfers.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewInvestments,
        label: AppL10n.tr(AppTranslationKeys.navInvestments),
        tooltip: AppL10n.tr(AppTranslationKeys.navInvestmentsTooltip),
        icon: ViewId.viewInvestments.getIcon(),
      ),
      MyNavigationItem(
        viewId: ViewId.viewStocks,
        label: AppL10n.tr(AppTranslationKeys.navStocks),
        tooltip: AppL10n.tr(AppTranslationKeys.navStocksTooltip),
        icon: ViewId.viewStocks.getIcon(),
      ),
      if (PreferenceController.to.includeRentalManagement)
        MyNavigationItem(
          viewId: ViewId.viewRentals,
          label: AppL10n.tr(AppTranslationKeys.navRentals),
          tooltip: AppL10n.tr(AppTranslationKeys.navRentalsTooltip),
          icon: ViewId.viewRentals.getIcon(),
        ),

      if (!kIsWeb && (Platform.isMacOS || Platform.isWindows))
        MyNavigationItem(
          viewId: ViewId.viewAI,
          label: AppL10n.tr(AppTranslationKeys.aiAssistant),
          tooltip: AppL10n.tr(AppTranslationKeys.navAiAssistantTooltip),
          icon: ViewId.viewAI.getIcon(),
        ),
    ];

    return appBarDestinations;
  }

  /// Returns the position of [selectedView] among [items], or null when that view has no destination.
  int? getSelectedIndex(List<MyNavigationItem> items) {
    final int index = items.indexWhere((MyNavigationItem item) => item.viewId == selectedView);
    return index < 0 ? null : index;
  }
}
