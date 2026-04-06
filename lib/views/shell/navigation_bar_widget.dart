import 'package:money/data/models/navigation_item_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';

// Exports
export 'package:flutter/material.dart';
export 'package:money/widgets/pure/scale_down_widget.dart';

const double _navRailMinWidth = 50.0;
const double _navBarHeight = 52.0;

/// A stateless widget for my navigation bar.
class MyNavigationBar extends StatelessWidget {
  const MyNavigationBar({
    super.key,
    required this.orientation,
    required this.selectedIndex,
    required this.onSelected,
  });

  final void Function(int) onSelected;
  final Axis orientation;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (orientation == Axis.vertical) {
      final List<NavigationRailDestination> destinations = geMenuItemsFortNavRail();
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
              onDestinationSelected: (final int index) {
                onSelected(index);
              },
            ),
          ),
        ),
      );
    }
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (final int index) {
        onSelected(index);
      },
      destinations: geMenuItemsFortNavBar(),
      height: _navBarHeight,
      indicatorColor: getColorTheme(context).onSecondary,
      backgroundColor: getColorTheme(context).secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
    );
  }

  /// Returns navigation destinations for bottom navigation bar.
  List<NavigationDestination> geMenuItemsFortNavBar() {
    return getAppBarDestinations()
        .map(
          (final MyNavigationItem item) => NavigationDestination(
            key: item.key,
            label: item.label,
            tooltip: AppL10n.tr(AppTranslationKeys.navShowLabel, params: <String, String>{'label': item.label}),
            icon: item.icon,
            selectedIcon: item.icon,
          ),
        )
        .toList();
  }

  /// Returns navigation destinations for navigation rail.
  List<NavigationRailDestination> geMenuItemsFortNavRail() {
    return getAppBarDestinations()
        .map(
          (final MyNavigationItem item) => NavigationRailDestination(
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
        label: AppL10n.tr(AppTranslationKeys.navCashflow),
        tooltip: AppL10n.tr(AppTranslationKeys.navCashflowTooltip),
        icon: ViewId.viewCashFlow.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navEvents),
        tooltip: AppL10n.tr(AppTranslationKeys.navEventsTooltip),
        icon: ViewId.viewEvents.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navAccounts),
        tooltip: AppL10n.tr(AppTranslationKeys.navAccountsTooltip),
        icon: ViewId.viewAccounts.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navCategories),
        tooltip: AppL10n.tr(AppTranslationKeys.navCategoriesTooltip),
        icon: ViewId.viewCategories.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navPayees),
        tooltip: AppL10n.tr(AppTranslationKeys.navPayeesTooltip),
        icon: ViewId.viewPayees.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navAliases),
        tooltip: AppL10n.tr(AppTranslationKeys.navAliasesTooltip),
        icon: ViewId.viewAliases.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navTransactions),
        tooltip: AppL10n.tr(AppTranslationKeys.navTransactionsTooltip),
        icon: ViewId.viewTransactions.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navTransfers),
        tooltip: AppL10n.tr(AppTranslationKeys.navTransfersTooltip),
        icon: ViewId.viewTransfers.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navInvestments),
        tooltip: AppL10n.tr(AppTranslationKeys.navInvestmentsTooltip),
        icon: ViewId.viewInvestments.getIcon(),
      ),
      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.navStocks),
        tooltip: AppL10n.tr(AppTranslationKeys.navStocksTooltip),
        icon: ViewId.viewStocks.getIcon(),
      ),
      if (PreferenceController.to.includeRentalManagement)
        MyNavigationItem(
          label: AppL10n.tr(AppTranslationKeys.navRentals),
          tooltip: AppL10n.tr(AppTranslationKeys.navRentalsTooltip),
          icon: ViewId.viewRentals.getIcon(),
        ),

      MyNavigationItem(
        label: AppL10n.tr(AppTranslationKeys.aiAssistant),
        tooltip: AppL10n.tr(AppTranslationKeys.navAiAssistantTooltip),
        icon: ViewId.viewAI.getIcon(),
      ),
    ];

    return appBarDestinations;
  }
}
