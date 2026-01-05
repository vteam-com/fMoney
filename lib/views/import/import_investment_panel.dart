import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/views/models/accounts/account.dart';
import 'package:money/views/models/categories/category.dart';
import 'package:money/views/models/investments/investment_types.dart';
import 'package:money/views/panels/dialog/picker_account.dart';
import 'package:money/views/panels/dialog/picker_category.dart';
import 'package:money/views/panels/dialog/picker_edit_box_date.dart';
import 'package:money/views/panels/dialog/picker_investment_type.dart';
import 'package:money/widgets/form_field_widget.dart';
import 'package:money/widgets/my_text_input.dart';

class InvestmentImportFields {
  InvestmentImportFields({
    required this.account,
    required this.date,
    required this.investmentType,
    required this.category,
    required this.symbol,
    required this.units,
    required this.amountPerUnit,
    required this.transactionAmount,
    required this.description,
  });

  Account account;
  double amountPerUnit;
  Category category;
  DateTime date;
  String description;
  InvestmentType investmentType;
  String symbol;
  double transactionAmount;
  double units;
}

/// use for free style text to transaction import
class ImportInvestmentPanel extends StatefulWidget {
  const ImportInvestmentPanel({super.key, required this.inputFields});

  final InvestmentImportFields inputFields;

  @override
  ImportInvestmentPanelState createState() => ImportInvestmentPanelState();
}

class ImportInvestmentPanelState extends State<ImportInvestmentPanel> {
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
              spacing: 24,
              children: <Widget>[
                // Title
                Text(
                  'Add Investment Transaction',
                  style: getTextTheme(context).titleLarge,
                ),

                // Account
                myFormField(
                  title: 'To Account',
                  child: pickerAccount(
                    selected: widget.inputFields.account,
                    onSelected: (Account? selectedAccount) {
                      if (selectedAccount != null) {
                        widget.inputFields.account = selectedAccount;
                      }
                    },
                  ),
                ),

                // Date
                myFormField(
                  title: 'Date',
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
                  title: 'Investment Type',
                  child: pickerInvestmentType(
                    itemSelected: widget.inputFields.investmentType,
                    onSelected: (final InvestmentType newSelection) {
                      widget.inputFields.investmentType = newSelection;
                    },
                  ),
                ),

                // Investment Category
                myFormField(
                  title: 'Category',
                  child: pickerCategory(
                    itemSelected: widget.inputFields.category,
                    onSelected: (final Category? newSelection) {
                      if (newSelection != null) {
                        widget.inputFields.category = newSelection;
                      }
                    },
                  ),
                ),

                // Symbol
                MyTextInput(hintText: 'Symbol', controller: _controllerSymbol),

                // Units
                MyTextInput(hintText: 'Units', controller: _controllerUnites),

                // Amount per unit
                MyTextInput(
                  hintText: 'Amount per unit',
                  controller: _controllerAmount,
                ),

                // Transaction Amount
                MyTextInput(
                  hintText: 'Total Transaction Amount',
                  controller: _controllerTransactionAmount,
                ),

                // Description
                MyTextInput(
                  hintText: 'Description',
                  controller: _controllerDescription,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void removeFocus() {
    _focusNode.unfocus();
  }

  void requestFocus() {
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _updateInputFields() {
    widget.inputFields.symbol = _controllerSymbol.text;
    widget.inputFields.units = double.tryParse(_controllerUnites.text) ?? 0.0;
    widget.inputFields.amountPerUnit = double.tryParse(_controllerAmount.text) ?? 0.0;
    widget.inputFields.transactionAmount = double.tryParse(_controllerTransactionAmount.text) ?? 0.0;
    widget.inputFields.description = _controllerDescription.text;
  }
}
