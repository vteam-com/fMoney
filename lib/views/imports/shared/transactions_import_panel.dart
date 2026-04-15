import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/views/imports/shared/transactions_import_list_preview_widget.dart';
import 'package:money/widgets/columns/columns_input_widget.dart';
import 'package:money/widgets/columns/value_parser.dart';
import 'package:money/widgets/columns/value_quality.dart';
import 'package:money/widgets/components/my_segment_widget.dart';
import 'package:money/widgets/pickers/account_picker_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _panelWidth = 800.0;
const int _listPreviewFlex = 2;
const int _unsetId = -1;
const int _currencyFormatNative = 0;
const int _currencyFormatUsd = 1;

/// use for free style text to transaction import
class ImportTransactionsPanel extends StatefulWidget {
  const ImportTransactionsPanel({
    required this.account,
    required this.inputText,
    required this.onAccountChanged,
    required this.onTransactionsFound,
    this.preferredCurrencyCode,
    super.key,
  });
  final Account account;
  final String inputText;
  final void Function(Account accountSelected) onAccountChanged;
  final void Function(ValuesParser parser) onTransactionsFound;

  /// Optional ISO-4217 currency code used to initialize the import amount format toggle.
  final String? preferredCurrencyCode;
  @override
  ImportTransactionsPanelState createState() => ImportTransactionsPanelState();
}

/// State for import transactions panel.
class ImportTransactionsPanelState extends State<ImportTransactionsPanel> {
  late Account _account;
  bool _allowCurrencyAutoDetection = true;
  final FocusNode _focusNode = FocusNode();
  final List<String> _possibleDateFormats = <String>[
    // Dash
    'yyyy-MM-dd',
    'yy-MM-dd',
    'yyyy-dd-MM',
    'yy-dd-MM',
    'MM-dd-yyyy',
    'MM-dd-yy',
    'dd-MM-yyyy',
    'dd-MM-yy',
    // Slash
    'yyyy/MM/dd',
    'yy/MM/dd',
    'yyyy/dd/MM',
    'yy/dd/MM',
    'MM/dd/yyyy',
    'MM/dd/yy',
    'dd/MM/yyyy',
    'dd/MM/yy',
  ];
  late String _textToParse;
  int _userChoiceDebitVsCredit = 0;
  int _userChoiceNativeVsUSD = 0;
  List<ValuesQuality> _values = <ValuesQuality>[];
  late String userChoiceOfDateFormat = _possibleDateFormats.first;
  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _textToParse = widget.inputText;

    final int? preferredCurrencyFormat = _resolvePreferredCurrencyFormat(widget.preferredCurrencyCode);
    if (preferredCurrencyFormat != null) {
      _userChoiceNativeVsUSD = preferredCurrencyFormat;
      _allowCurrencyAutoDetection = false;
    }

    convertAndNotify(context, _textToParse);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ValuesParser.evaluateExistence(
      accountId: _account.uniqueId,
      values: _values,
      transactionExistsCallback:
          ({
            required int accountId,
            required DateTime dateTime,
            required double amount,
          }) =>
              null !=
              Data().transactions.findExistingTransaction(
                accountId: accountId,
                dateRange: DateRange(min: dateTime.startOfDay, max: dateTime.endOfDay),
                amount: amount,
              ),
    );

    return Focus(
      onFocusChange: (bool _) {},
      child: KeyboardListener(
        focusNode: _focusNode,
        child: SizedBox(
          width: _panelWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeaderAndAccountPicker(),

              gapMedium(),

              Expanded(
                flex: 1,
                child: InputByColumnsOrFreeStyle(
                  inputText: _textToParse,
                  dateFormat: userChoiceOfDateFormat,
                  currency: _userChoiceNativeVsUSD == 0
                      ? _account.getAccountCurrencyAsText()
                      : Constants.defaultCurrency,
                  reverseAmountValue: _userChoiceDebitVsCredit == 1,
                  onChanged: (String newTextInput) {
                    setState(() {
                      convertAndNotify(context, newTextInput);
                      _textToParse = newTextInput;
                    });
                  },
                ),
              ),

              ///
              /// Date Format | Credit/Debit | Currency
              ///
              if (_values.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: SizeForPadding.large),
                  child: Row(
                    children: <Widget>[
                      _buildChoiceOfDateFormat(),
                      const Spacer(),
                      _buildChoiceOfDebitVsCredit(),
                      gapLarge(),
                      _buildChoiceOfAmountFormat(),
                    ],
                  ),
                ),

              const Divider(),
              gapMedium(),

              // Results
              Expanded(
                flex: _listPreviewFlex,
                child: Center(
                  child: ImportTransactionsListPreview(
                    accountId: _account.uniqueId,
                    values: _values,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Converts input text and notifies about detected currency format.
  void convertAndNotify(BuildContext context, String inputText) {
    if (_allowCurrencyAutoDetection) {
      // Detect currency format from input text if any amounts exist
      final int detectedFormat = detectCurrencyFormat(inputText);
      if (detectedFormat != _unsetId) {
        _userChoiceNativeVsUSD = detectedFormat;
      }
    }

    final ValuesParser parser = ValuesParser(
      dateFormat: userChoiceOfDateFormat,
      currency: _userChoiceNativeVsUSD == _currencyFormatNative
          ? _account.getAccountCurrencyAsText()
          : Constants.defaultCurrency,
      reverseAmountValue: _userChoiceDebitVsCredit == _currencyFormatUsd,
    );
    parser.convertInputTextToTransactionList(context, inputText);
    _values = parser.lines;
    widget.onTransactionsFound(parser);
  }

  /// Detects the currency format from input text
  /// Returns: 0 for native currency format, 1 for USD format, -1 if no amounts found
  int detectCurrencyFormat(String input) {
    if (input.isEmpty) {
      return _unsetId;
    }

    // Split input into lines
    final List<String> lines = input.split('\n');
    for (String line in lines) {
      // Look for number patterns with currency symbols
      if (line.contains(RegExp(r'[€£¥]'))) {
        return _currencyFormatNative; // Native currency detected
      }
      if (line.contains('\$')) {
        return _currencyFormatUsd; // USD detected
      }
    }

    // If no explicit currency symbols, try to detect format based on number patterns
    for (final String line in lines) {
      // US format (1,234.56)
      if (line.contains(RegExp(r'\d{1,3}(?:,\d{3})*\.\d{2}'))) {
        return _currencyFormatUsd;
      }
      // European format (1.234,56 or 1,234.56)
      if (line.contains(RegExp(r'\d{1,3}(?:\.\d{3})*,\d{2}'))) {
        return _currencyFormatNative;
      }
    }

    return _unsetId; // No clear format detected
  }

  /// Requests focus for the text input field.
  void requestFocus() {
    FocusScope.of(context).requestFocus(_focusNode);
  }

  /// Offer assistance for the currency format
  Widget _buildChoiceOfAmountFormat() {
    if (_account.getAccountCurrencyAsText() == Constants.defaultCurrency) {
      // No need to offer switching currency input format
      return buildCurrencyWidget(Constants.defaultCurrency);
    }

    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        ButtonSegment<int>(
          value: 0,
          label: _account.getAccountCurrencyAsWidget(),
        ),
        ButtonSegment<int>(
          value: 1,
          label: buildCurrencyWidget(Constants.defaultCurrency),
        ),
      ],
      selectedId: _userChoiceNativeVsUSD,
      onSelectionChanged: (final int newSelection) {
        setState(() {
          _userChoiceNativeVsUSD = newSelection;
          convertAndNotify(context, _textToParse);
        });
      },
    );
  }

  /// Builds a dropdown to choose the date format used to parse imported transactions.
  Widget _buildChoiceOfDateFormat() {
    if (_values.isEmpty) {
      return const SizedBox();
    }

    final List<String> listOfDateAsStrings = _values.map((ValuesQuality entry) => entry.date.asString()).toList();

    final List<String> choiceOfDateFormat = getPossibleDateFormatsForAllValues(
      listOfDateAsStrings,
    );

    if (choiceOfDateFormat.isEmpty) {
      return Text(
        AppL10n.tr(AppTranslationKeys.badDateFormat),
        style: TextStyle(
          color: context.colorTheme.getColorForState(ColorState.error),
        ),
      );
    }

    // make sure that the last choice is a valid one
    if (!choiceOfDateFormat.contains(userChoiceOfDateFormat)) {
      userChoiceOfDateFormat = choiceOfDateFormat.first;
    }

    return DropdownButton<String>(
      dropdownColor: getColorTheme(context).secondaryContainer,
      value: userChoiceOfDateFormat,
      items: choiceOfDateFormat
          .map(
            (String item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: getColorTheme(context).onSecondaryContainer,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (final String? value) {
        setState(() {
          userChoiceOfDateFormat = value!;
          convertAndNotify(context, _textToParse);
        });
      },
    );
  }

  /// Builds a selector to interpret amounts as debit vs credit.
  Widget _buildChoiceOfDebitVsCredit() {
    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        ButtonSegment<int>(value: 0, label: Text(AppL10n.tr(AppTranslationKeys.credit))),
        ButtonSegment<int>(value: 1, label: Text(AppL10n.tr(AppTranslationKeys.debit))),
      ],
      selectedId: _userChoiceDebitVsCredit,
      onSelectionChanged: (final int newSelection) {
        setState(() {
          _userChoiceDebitVsCredit = newSelection;
          convertAndNotify(context, _textToParse);
        });
      },
    );
  }

  /// Builds the header row showing import target account selection.
  Widget _buildHeaderAndAccountPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          AppL10n.tr(AppTranslationKeys.importTransactionToAccount),
          style: getTextTheme(context).bodyLarge,
        ),
        gapLarge(),
        Expanded(
          child: pickerAccount(
            accountNames: Data().accounts.getSortedAccountNames(),
            selectedName: _account.fieldName.value,
            onSelected: (String? name) {
              final Account? accountSelected = name != null ? Data().accounts.getByName(name) : null;
              if (accountSelected != null) {
                setState(() {
                  _account = accountSelected;
                  widget.onAccountChanged(_account);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  /// Resolves the initial currency format selector value from [preferredCurrencyCode].
  int? _resolvePreferredCurrencyFormat(final String? preferredCurrencyCode) {
    if (preferredCurrencyCode == null) {
      return null;
    }

    final String normalizedCurrencyCode = preferredCurrencyCode.trim().toUpperCase();
    if (normalizedCurrencyCode.isEmpty) {
      return null;
    }

    return normalizedCurrencyCode == Constants.defaultCurrency ? _currencyFormatUsd : _currencyFormatNative;
  }
}
