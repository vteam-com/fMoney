import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_import_fields_helper.dart';
import 'package:money/widgets/pickers/account_picker_widget.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_date_picker_widget.dart';
import 'package:money/widgets/pickers/picker_investment_type.dart';
import 'package:money/widgets/pure/form_field_widget.dart';
import 'package:money/widgets/pure/my_text_input_widget.dart';

const double _panelSpacing = 24.0;

/// use for free style text to transaction import
class ImportInvestmentPanel extends StatefulWidget {
  const ImportInvestmentPanel({super.key, required this.inputFields});

  final InvestmentImportFields inputFields;

  @override
  State<ImportInvestmentPanel> createState() => _ImportInvestmentPanelState();
}

class _ImportInvestmentPanelState extends State<ImportInvestmentPanel> {
  late final TextEditingController _controllerAmount = TextEditingController(
    text: widget.inputFields.amountPerUnit.toString(),
  );

  late final TextEditingController _controllerDescription = TextEditingController(
    text: widget.inputFields.description.toString(),
  );

  late final TextEditingController _controllerSymbol = TextEditingController(
    text: widget.inputFields.symbol.toString(),
  );

  late final TextEditingController _controllerTransactionAmount = TextEditingController(
    text: widget.inputFields.transactionAmount.toString(),
  );

  late final TextEditingController _controllerUnites = TextEditingController(
    text: widget.inputFields.units.toString(),
  );

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controllerSymbol.addListener(_updateInputFields);
    _controllerUnites.addListener(_updateInputFields);
    _controllerAmount.addListener(_updateInputFields);
    _controllerTransactionAmount.addListener(_updateInputFields);
    _controllerDescription.addListener(_updateInputFields);
  }

  @override
  void dispose() {
    _controllerSymbol.dispose();
    _controllerUnites.dispose();
    _controllerAmount.dispose();
    _controllerTransactionAmount.dispose();
    _controllerDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: KeyboardListener(
        focusNode: _focusNode,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: _panelSpacing,
              children: <Widget>[
                // Title
                Text(
                  AppL10n.tr(AppTranslationKeys.addInvestmentTransaction),
                  style: getTextTheme(context).titleLarge,
                ),

                // Account
                myFormField(
                  title: AppL10n.tr(AppTranslationKeys.toAccount),
                  child: pickerAccount(
                    accountNames: Data().accounts.getSortedAccountNames(),
                    selectedName: widget.inputFields.account.fieldName.value,
                    onSelected: (String? name) {
                      final Account? selectedAccount = name != null ? Data().accounts.getByName(name) : null;
                      if (selectedAccount != null) {
                        widget.inputFields.account = selectedAccount;
                      }
                    },
                  ),
                ),

                // Date
                myFormField(
                  title: AppL10n.tr(AppTranslationKeys.date),
                  child: PickerEditBoxDate(
                    initialValue: dateToString(widget.inputFields.date),
                    onChanged: (String? newDateSelected) {
                      if (newDateSelected != null) {
                        widget.inputFields.date = attemptToGetDateFromText(newDateSelected) ?? DateTime.now();
                      }
                    },
                  ),
                ),

                // Investment Type
                myFormField(
                  title: AppL10n.tr(AppTranslationKeys.investmentType),
                  child: pickerInvestmentType(
                    itemSelected: widget.inputFields.investmentType,
                    onSelected: (InvestmentType newSelection) {
                      widget.inputFields.investmentType = newSelection;
                    },
                  ),
                ),

                // Investment Category
                myFormField(
                  title: AppL10n.tr(AppTranslationKeys.category),
                  child: pickerCategory(
                    categoryNames: Data().categories.getCategoriesAsStrings(),
                    selectedName: widget.inputFields.category.fieldName.value,
                    onSelected: (String? name) {
                      final Category? newSelection = name != null ? Data().categories.getByName(name) : null;
                      if (newSelection != null) {
                        widget.inputFields.category = newSelection;
                      }
                    },
                  ),
                ),

                // Symbol
                MyTextInput(
                  hintText: AppL10n.tr(AppTranslationKeys.symbol),
                  controller: _controllerSymbol,
                ),

                // Units
                MyTextInput(
                  hintText: AppL10n.tr(AppTranslationKeys.units),
                  controller: _controllerUnites,
                ),

                // Amount per unit
                MyTextInput(
                  hintText: AppL10n.tr(AppTranslationKeys.amountPerUnit),
                  controller: _controllerAmount,
                ),

                // Transaction Amount
                MyTextInput(
                  hintText: AppL10n.tr(AppTranslationKeys.totalTransactionAmount),
                  controller: _controllerTransactionAmount,
                ),

                // Description
                MyTextInput(
                  hintText: AppL10n.tr(AppTranslationKeys.description),
                  controller: _controllerDescription,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Requests focus for the investment panel input field.
  void requestFocus() {
    FocusScope.of(context).requestFocus(_focusNode);
  }

  /// Updates the bound input fields model from the current text controller values.
  void _updateInputFields() {
    widget.inputFields.symbol = _controllerSymbol.text;
    widget.inputFields.units = double.tryParse(_controllerUnites.text) ?? 0.0;
    widget.inputFields.amountPerUnit = double.tryParse(_controllerAmount.text) ?? 0.0;
    widget.inputFields.transactionAmount = double.tryParse(_controllerTransactionAmount.text) ?? 0.0;
    widget.inputFields.description = _controllerDescription.text;
  }
}
