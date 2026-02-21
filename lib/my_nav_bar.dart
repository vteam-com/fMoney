import 'package:money/data/models/my_navigation_item.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/scale_down.dart';

// Exports
export 'package:flutter/material.dart';
export 'package:money/widgets/pure/scale_down.dart';

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
            tooltip: 'Show ${item.label}',
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
        label: 'Cashflow',
        tooltip: 'Show your Cash Flow',
        icon: ViewId.viewCashFlow.getIcon(),
      ),
      MyNavigationItem(
        label: 'Events',
        tooltip: 'Your life events',
        icon: ViewId.viewEvents.getIcon(),
      ),
      MyNavigationItem(
        label: 'Accounts',
        tooltip: 'Show Accounts',
        icon: ViewId.viewAccounts.getIcon(),
      ),
      MyNavigationItem(
        label: 'Categories',
        tooltip: 'Show Categories',
        icon: ViewId.viewCategories.getIcon(),
      ),
      MyNavigationItem(
        label: 'Payees',
        tooltip: 'Show Payees',
        icon: ViewId.viewPayees.getIcon(),
      ),
      MyNavigationItem(
        label: 'Aliases',
        tooltip: 'Show Aliases',
        icon: ViewId.viewAliases.getIcon(),
      ),
      MyNavigationItem(
        label: 'Transactions',
        tooltip: 'Show Transactions',
        icon: ViewId.viewTransactions.getIcon(),
      ),
      MyNavigationItem(
        label: 'Transfers',
        tooltip: 'View transfers between accounts',
        icon: ViewId.viewTransfers.getIcon(),
      ),
      MyNavigationItem(
        label: 'Investments',
        tooltip: 'Investment transactions',
        icon: ViewId.viewInvestments.getIcon(),
      ),
      MyNavigationItem(
        label: 'Stocks',
        tooltip: 'Stocks tracking',
        icon: ViewId.viewStocks.getIcon(),
      ),
      if (PreferenceController.to.includeRentalManagement)
        MyNavigationItem(
          label: 'Rentals',
          tooltip: 'Rentals',
          icon: ViewId.viewRentals.getIcon(),
        ),

      MyNavigationItem(
        label: 'AI Assistant',
        tooltip: 'AI-powered financial insights',
        icon: ViewId.viewAI.getIcon(),
      ),
    ];

    return appBarDestinations;
  }
}
