import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/data/picker_account.dart';
import 'package:money/views/import/import_transactions_list_preview.dart';
import 'package:money/views/models/account.dart';
import 'package:money/widgets/columns_input.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/my_segment.dart';
import 'package:money/widgets/theme_custom.dart';
import 'package:money/widgets/value_parser.dart';
import 'package:money/widgets/widgets_domain/money_widget.dart';

/// use for free style text to transaction import
class ImportTransactionsPanel extends StatefulWidget {
  const ImportTransactionsPanel({
    required this.account,
    required this.inputText,
    required this.onAccountChanged,
    required this.onTransactionsFound,
    super.key,
  });

  final Account account;
  final String inputText;
  final void Function(Account accountSelected) onAccountChanged;
  final void Function(ValuesParser parser) onTransactionsFound;

  @override
  ImportTransactionsPanelState createState() => ImportTransactionsPanelState();
}

class ImportTransactionsPanelState extends State<ImportTransactionsPanel> {
  late Account _account;

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
      onFocusChange: (bool hasFocus) {},
      child: KeyboardListener(
        focusNode: _focusNode,
        child: SizedBox(
          width: 800,
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
                flex: 2,
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

  void convertAndNotify(BuildContext context, String inputText) {
    // Detect currency format from input text if any amounts exist
    final int detectedFormat = detectCurrencyFormat(inputText);
    if (detectedFormat != -1) {
      _userChoiceNativeVsUSD = detectedFormat;
    }

    final ValuesParser parser = ValuesParser(
      dateFormat: userChoiceOfDateFormat,
      currency: _userChoiceNativeVsUSD == 0 ? _account.getAccountCurrencyAsText() : Constants.defaultCurrency,
      reverseAmountValue: _userChoiceDebitVsCredit == 1,
    );
    parser.convertInputTextToTransactionList(context, inputText);
    _values = parser.lines;
    widget.onTransactionsFound(parser);
  }

  /// Detects the currency format from input text
  /// Returns: 0 for native currency format, 1 for USD format, -1 if no amounts found
  int detectCurrencyFormat(String input) {
    if (input.isEmpty) {
      return -1;
    }

    // Split input into lines
    final List<String> lines = input.split('\n');
    for (String line in lines) {
      // Look for number patterns with currency symbols
      if (line.contains(RegExp(r'[€£¥]'))) {
        return 0; // Native currency detected
      }
      if (line.contains('\$')) {
        return 1; // USD detected
      }
    }

    // If no explicit currency symbols, try to detect format based on number patterns
    for (final String line in lines) {
      // US format (1,234.56)
      if (line.contains(RegExp(r'\d{1,3}(?:,\d{3})*\.\d{2}'))) {
        return 1;
      }
      // European format (1.234,56 or 1,234.56)
      if (line.contains(RegExp(r'\d{1,3}(?:\.\d{3})*,\d{2}'))) {
        return 0;
      }
    }

    return -1; // No clear format detected
  }

  void removeFocus() {
    _focusNode.unfocus();
  }

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
        'Bad Date Format',
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

  Widget _buildChoiceOfDebitVsCredit() {
    return mySegmentSelector(
      context: context,
      segments: const <ButtonSegment<int>>[
        ButtonSegment<int>(value: 0, label: Text('Credit')),
        ButtonSegment<int>(value: 1, label: Text('Debit')),
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

  Widget _buildHeaderAndAccountPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          'Import transaction to account',
          style: getTextTheme(context).bodyLarge,
        ),
        gapLarge(),
        Expanded(
          child: pickerAccount(
            selected: _account,
            onSelected: (final Account? accountSelected) {
              setState(() {
                _account = accountSelected!;
                widget.onAccountChanged(_account);
              });
            },
          ),
        ),
      ],
    );
  }
}
