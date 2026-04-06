import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/shared/presentation/app_scope.dart';
import 'package:money/shared/presentation/provider_data_file_controller.dart';
import 'package:money/views/home/ai/view_ai.dart';
import 'package:money/views/home/view_accounts.dart';
import 'package:money/views/home/view_aliases.dart';
import 'package:money/views/home/view_cashflow.dart';
import 'package:money/views/home/view_categories.dart';
import 'package:money/views/home/view_events.dart';
import 'package:money/views/home/view_investments.dart';
import 'package:money/views/home/view_payees.dart';
import 'package:money/views/home/view_policy.dart';
import 'package:money/views/home/view_rentals.dart';
import 'package:money/views/home/view_stocks.dart';
import 'package:money/views/home/view_transactions.dart';
import 'package:money/views/home/view_transfers.dart';
import 'package:money/views/imports/import_csv.dart';
import 'package:money/views/imports/import_qfx.dart';
import 'package:money/views/shell/app_bar.dart';
import 'package:money/views/shell/my_nav_bar.dart';
import 'package:money/widgets/components/app_scaffold.dart';
import 'package:money/widgets/pure/drop_zone.dart';
import 'package:money/widgets/pure/working.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:path/path.dart' as path;

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
                  onFilesDropped: (List<String> filePaths) {
                    for (final String filePath in filePaths) {
                      final String extension = path.extension(filePath).toLowerCase();
                      if (extension == '.csv') {
                        importCSV(context, filePath);
                      } else {
                        // Assuming other types default to QFX, or you can add more checks
                        importQFX(context, filePath);
                      }
                    }
                  },
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
