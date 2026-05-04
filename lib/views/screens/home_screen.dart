import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/home/accounts/accounts_view.dart';
import 'package:money/views/home/ai/ai_view.dart';
import 'package:money/views/home/aliases/aliases_view.dart';
import 'package:money/views/home/cashflow/cashflow_view.dart';
import 'package:money/views/home/categories/categories_view.dart';
import 'package:money/views/home/events/events_view.dart';
import 'package:money/views/home/investments/investments_view.dart';
import 'package:money/views/home/payees/payees_view.dart';
import 'package:money/views/home/policy/policy_view.dart';
import 'package:money/views/home/rentals/rentals_view.dart';
import 'package:money/views/home/stocks/stocks_view.dart';
import 'package:money/views/home/transactions/transactions_view.dart';
import 'package:money/views/home/transfers/transfers_view.dart';
import 'package:money/views/imports/import_file_dispatcher.dart';
import 'package:money/views/shell/app_bar_widget.dart';
import 'package:money/views/shell/navigation_bar_widget.dart';
import 'package:money/widgets/components/app_scaffold_widget.dart';
import 'package:money/widgets/pure/drop_zone_widget.dart';
import 'package:money/widgets/pure/working_indicator_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';

/// Represents home page.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Builds the main application page and switches content based on viewport size.
  @override
  Widget build(BuildContext context) {
    final DataFileController dataController = DataFileController.to;
    return ListenableBuilder(
      listenable: dataController,
      builder: (BuildContext context, Widget? _) {
        return myScaffold(
          context,
          const MyAppBar(),
          dataController.isLoading.value
              ? const WorkingIndicator()
              : DropZone(
                  onFilesDropped: (List<String> filePaths) => handleDroppedFiles(context, filePaths),
                  child: Container(
                    color: getColorTheme(context).secondaryContainer,
                    child: _buildAdaptiveContent(context),
                  ),
                ),
        );
      },
    );
  }

  /// Builds the main content area based on current screen size.
  ///
  /// This method uses the `Obx` widget to rebuild the content area when the screen size changes.
  /// It returns either the large-screen layout or the small-screen layout based on the current screen size.
  Widget _buildAdaptiveContent(BuildContext context) {
    return ListenableBuilder(
      listenable: AppScope.of(context).themeController,
      builder: (BuildContext context, Widget? _) {
        if (context.isWidthSmall) {
          // small screens
          return _buildContentForSmallSurface(context);
        } else {
          // Large screens
          return _buildContentForLargeSurface(context);
        }
      },
    );
  }

  /// Builds the large-screen layout with a vertical navigation bar.
  ///
  /// This method returns a `SafeArea` widget with a `Row` child, containing the vertical navigation bar and the main content area.
  Widget _buildContentForLargeSurface(final BuildContext context) {
    return SafeArea(
      bottom: false,
      top: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MyNavigationBar(
            orientation: Axis.vertical,
            key: Key(PreferenceController.to.currentView.toString()),
            onSelected: _handleSubViewSelectionChanged,
            selectedIndex: PreferenceController.to.currentView.index,
          ),
          Expanded(
            child: Container(
              color: getColorTheme(context).secondaryContainer,
              child: _getSubView(),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the small-screen layout with a bottom navigation bar.
  Widget _buildContentForSmallSurface(final BuildContext _) {
    return Column(
      children: <Widget>[
        Expanded(child: _getSubView()),
        MyNavigationBar(
          orientation: Axis.horizontal,
          key: Key(PreferenceController.to.currentView.toString()),
          onSelected: _handleSubViewSelectionChanged,
          selectedIndex: PreferenceController.to.currentView.index,
        ),
      ],
    );
  }

  /// Returns the currently selected sub-view widget.
  Widget _getSubView() {
    switch (PreferenceController.to.currentView) {
      case ViewId.viewAccounts:
        return ViewAccounts(
          includeClosedAccount: PreferenceController.to.includeClosedAccounts,
        );

      case ViewId.viewCategories:
        return const ViewCategories();

      case ViewId.viewPayees:
        return const ViewPayees();

      case ViewId.viewAliases:
        return const ViewAliases();

      case ViewId.viewTransactions:
        return const ViewTransactions();

      case ViewId.viewTransfers:
        return const ViewTransfers();

      case ViewId.viewInvestments:
        return const ViewInvestments();

      case ViewId.viewStocks:
        return const ViewStocks();

      case ViewId.viewEvents:
        return const ViewEvents();

      case ViewId.viewRentals:
        return const ViewRentals();

      case ViewId.viewPolicy:
        return const PolicyScreen();

      case ViewId.viewCashFlow:
        return const ViewCashFlow();

      case ViewId.viewAI:
        return const ViewAI();
    }
  }

  void _handleSubViewSelectionChanged(final int selectedIndex) {
    PreferenceController.to.setView(ViewId.values[selectedIndex]);
  }
}
