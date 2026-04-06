import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/views/imports/transfer/transfer_import_fields_model.dart';
import 'package:money/widgets/pickers/account_picker_widget.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_date_picker_widget.dart';
import 'package:money/widgets/pure/form_field_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/my_text_input_widget.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _panelSpacing = 24.0;
const double _zeroDouble = 0.0;

/// use for free style text to transaction import
class ImportFieldsForTransferPanel extends StatefulWidget {
  const ImportFieldsForTransferPanel({super.key, required this.inputFields});

  final ImportFieldsForTransfer inputFields;

  @override
  State<ImportFieldsForTransferPanel> createState() => _ImportFieldsForTransferPanelState();
}

/// State for import fields for transfer panel.
class _ImportFieldsForTransferPanelState extends State<ImportFieldsForTransferPanel> {
  late final TextEditingController _controllerAmount = TextEditingController(
    text: widget.inputFields.amount.toString(),
  );

  late final TextEditingController _controllerDescription = TextEditingController(
    text: widget.inputFields.memo.toString(),
  );

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controllerAmount.addListener(_updateInputFields);
    _controllerDescription.addListener(_updateInputFields);
  }

  @override
  void dispose() {
    _controllerAmount.dispose();
    _controllerDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool validAccounts = widget.inputFields.validAccounts;

    return Focus(
      onFocusChange: (final bool _) {},
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
                  AppL10n.tr(AppTranslationKeys.recordATransferBetweenTwoAccounts),
                  style: getTextTheme(context).titleLarge,
                ),

                // From Account
                myFormField(
                  title: AppL10n.tr(AppTranslationKeys.fromAccount),
                  child: pickerAccount(
                    accountNames: Data().accounts.getSortedAccountNames(),
                    selectedName: widget.inputFields.accountFrom.fieldName.value,
                    onSelected: (String? name) {
                      final Account? selectedAccount = name != null ? Data().accounts.getByName(name) : null;
                      setState(() {
                        if (selectedAccount != null) {
                          widget.inputFields.accountFrom = selectedAccount;
                        }
                      });
                    },
                  ),
                ),
                // Display balance of the account
                WidgetFromData.fromDouble(widget.inputFields.accountFrom.balance),
                gapMedium(),
                // To Account
                myFormField(
                  title: AppL10n.tr(AppTranslationKeys.toAccount),
                  child: pickerAccount(
                    accountNames: Data().accounts.getSortedAccountNames(),
                    selectedName: widget.inputFields.accountTo.fieldName.value,
                    onSelected: (String? name) {
                      final Account? selectedAccount = name != null ? Data().accounts.getByName(name) : null;
                      setState(() {
                        if (selectedAccount != null) {
                          widget.inputFields.accountTo = selectedAccount;
                        }
                      });
                    },
                  ),
                ),
                // Display balance of the account
                WidgetFromData.fromDouble(widget.inputFields.accountTo.balance),
                gapMedium(),

                if (!validAccounts)
                  Text(
                    AppL10n.tr(AppTranslationKeys.pleaseSelectDifferentAccounts),
                    style: const TextStyle(color: Colors.red),
                  ),

                if (validAccounts)
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

                if (validAccounts)
                  // Category
                  myFormField(
                    title: AppL10n.tr(AppTranslationKeys.category),
                    child: pickerCategory(
                      categoryNames: Data().categories.getCategoriesAsStrings(),
                      selectedName: widget.inputFields.category?.fieldName.value,
                      onSelected: (String? name) {
                        final Category? newSelection = name != null ? Data().categories.getByName(name) : null;
                        if (newSelection != null) {
                          widget.inputFields.category = newSelection;
                        }
                      },
                    ),
                  ),

                if (validAccounts)
                  // Amount per unit
                  MyTextInput(
                    hintText: AppL10n.tr(AppTranslationKeys.amount),
                    controller: _controllerAmount,
                  ),

                if (validAccounts)
                  // Memo description
                  MyTextInput(
                    hintText: AppL10n.tr(AppTranslationKeys.memo),
                    controller: _controllerDescription,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Requests focus for the transfer panel input field.
  void requestFocus() {
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _updateInputFields() {
    widget.inputFields.amount = double.tryParse(_controllerAmount.text) ?? _zeroDouble;
    widget.inputFields.memo = _controllerDescription.text;
  }
}
