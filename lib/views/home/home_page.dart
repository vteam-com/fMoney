import 'package:get/get.dart';
import 'package:money/controller/data_controller.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/import/import_csv.dart'; // Added import for CSV
import 'package:money/import/import_qfx.dart';
import 'package:money/views/home/sub_views/app_bar.dart';
import 'package:money/views/home/sub_views/app_scaffold.dart';
import 'package:money/views/home/sub_views/my_nav_bar.dart';
import 'package:money/views/home/sub_views/view_accounts/view_accounts.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai.dart';
import 'package:money/views/home/sub_views/view_aliases/view_aliases.dart';
import 'package:money/views/home/sub_views/view_cashflow/view_cashflow.dart';
import 'package:money/views/home/sub_views/view_categories/view_categories.dart';
import 'package:money/views/home/sub_views/view_events/view_events.dart';
import 'package:money/views/home/sub_views/view_investments/view_investments.dart';
import 'package:money/views/home/sub_views/view_payees/view_payees.dart';
import 'package:money/views/home/sub_views/view_rentals/view_rentals.dart';
import 'package:money/views/home/sub_views/view_stocks/view_stocks.dart';
import 'package:money/views/home/sub_views/view_transactions/view_transactions.dart';
import 'package:money/views/home/sub_views/view_transfers/view_transfers.dart';
import 'package:money/views/policies/view_policy.dart';
import 'package:money/widgets/drop_zone.dart';
import 'package:money/widgets/working.dart';
import 'package:path/path.dart' as path; // Added import for path

import '../../controller/home_controller.dart';

RxInt subViewInt = 0.obs;

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final DataController dataController = Get.find();
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
  }

  Widget _buildAdaptiveContent(BuildContext context) {
    return Obx(() {
      if (context.isWidthSmall) {
        // small screens
        return _buildContentForSmallSurface(context);
      } else {
        // Large screens
        return _buildContentForLargeSurface(context);
      }
    });
  }

  Widget _buildContentForLargeSurface(final BuildContext context) {
    return SafeArea(
      bottom: false,
      top: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MyNavigationBar(
            orientation: Axis.vertical,
            key: Key(PreferenceController.to.currentView.value.toString()),
            onSelected: _handleSubViewSelectionChanged,
            selectedIndex: PreferenceController.to.currentView.value.index,
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

  Widget _buildContentForSmallSurface(final BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: _getSubView()),
        MyNavigationBar(
          orientation: Axis.horizontal,
          key: Key(PreferenceController.to.currentView.value.toString()),
          onSelected: _handleSubViewSelectionChanged,
          selectedIndex: PreferenceController.to.currentView.value.index,
        ),
      ],
    );
  }

  Widget _getSubView() {
    switch (PreferenceController.to.currentView.value) {
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
