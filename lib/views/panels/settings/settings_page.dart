import 'package:get/get.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/views/data.dart';
import 'package:money/views/providers/currency.dart';
import 'package:money/widgets/app_scaffold.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/my_text_input.dart';
import 'package:money/widgets/text_title.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// The `SettingsPage` class is a `GetView` that extends `GetxController`. It represents the settings page of the application.
/// This page allows the user to manage various settings, such as rental management, stock service API key, and currencies.
class SettingsPage extends GetView<GetxController> {
  /// Constructs a `SettingsPage` widget with the provided [key].
  const SettingsPage({super.key});

  /// Builds the settings page UI.
  @override
  Widget build(BuildContext context) {
    return myScaffold(
      context,
      AppBar(title: const TextTitle('Settings'), centerTitle: true),
      Center(
        child: SingleChildScrollView(
          child: Box(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: const Text('Rental'),
                  subtitle: const Text(
                    'Manage the expenses and rental income of properties.',
                  ),
                  value: PreferenceController.to.includeRentalManagement,
                  onChanged: (bool _) {
                    PreferenceController.to.includeRentalManagement = !PreferenceController.to.includeRentalManagement;
                  },
                ),
                const Divider(height: 50),
                MyTextInput(
                  hintText: 'Stock service API key from https://twelvedata.com',
                  controller: TextEditingController()..text = PreferenceController.to.apiKeyForStocks,
                ),
                const Divider(height: 50),
                _buildCurrenciesPanel(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the currencies panel showing configured currencies and their display formats.
  Widget _buildCurrenciesPanel(final BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    for (final Currency currency in Data().currencies.iterableList()) {
      widgets.add(
        Container(
          decoration: BoxDecoration(
            color: getColorTheme(context).surfaceContainerHighest,
            border: Border.all(color: getColorTheme(context).outline),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(4),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(currency.fieldName.value),
                  buildCurrencyWidget(currency.fieldSymbol.value),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(currency.fieldRatio.value.toString()),
                  Text(currency.fieldCultureCode.value),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}
