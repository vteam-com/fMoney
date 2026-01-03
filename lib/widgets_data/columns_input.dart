import 'package:money/helpers/constants.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/columns/input_values.dart';
import 'package:money/widgets_data/value_parser.dart';

/// A widget that provides input functionality for financial data in either
/// three-column format (date, description, amount) or single-column freestyle format.
class InputByColumnsOrFreeStyle extends StatefulWidget {
  const InputByColumnsOrFreeStyle({
    super.key,
    required this.inputText,
    required this.dateFormat,
    required this.currency,
    required this.onChanged,
    required this.reverseAmountValue,
  });

  /// The currency symbol or code to use for amounts
  final String currency;

  /// The date format to use for parsing dates (e.g., 'dd/MM/yyyy')
  final String dateFormat;

  /// The initial input text to populate the fields
  final String inputText;

  /// Callback function triggered when input changes
  final void Function(String) onChanged;

  /// Whether to reverse the sign of amount values
  final bool reverseAmountValue;

  @override
  State<InputByColumnsOrFreeStyle> createState() => _InputByColumnsOrFreeStyleState();
}

class _InputByColumnsOrFreeStyleState extends State<InputByColumnsOrFreeStyle> {
  final TextEditingController _controllerColumn1 = TextEditingController();

  final TextEditingController _controllerColumn2 = TextEditingController();

  final TextEditingController _controllerColumn3 = TextEditingController();

  final TextEditingController _controllerSingleColumn = TextEditingController();

  final Debouncer _debouncer = Debouncer();

  bool _freeStyleInput = false;

  bool _pauseTextSync = false;

  @override
  void initState() {
    _updateAllTextControllerContentFromRawText(widget.inputText);

    _startListening();

    super.initState();
  }

  @override
  void dispose() {
    _controllerSingleColumn.dispose();
    _stopListening();
    _controllerColumn1.dispose();
    _controllerColumn2.dispose();
    _controllerColumn3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _freeStyleInput ? 1 : 0,
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: const <Widget>[
              Tab(
                key: Key('key_import_tab_three_columns'),
                child: Text('3 columns'),
              ),
              Tab(
                key: Key('key_import_tab_free_style'),
                child: Text('Free style'),
              ),
            ],
            onTap: (int index) {
              _freeStyleInput = index == 1;
              if (_freeStyleInput) {
                _fromThreeToOneColumn();
              } else {
                _fromOneToThreeColumn();
              }
              _notifyChanged();
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: SizeForPadding.normal,
              ),
              child: TabBarView(
                children: <Widget>[
                  // Content for 3 columns
                  _buildInputFor3Columns(),
                  // Content for 1 column
                  _buildInputFor1Column(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the single-column freestyle input view
  Widget _buildInputFor1Column() {
    return Center(
      child: InputValues(
        key: const Key('key_input_value'),
        title: 'Date; Description; Amount',
        controller: _controllerSingleColumn,
        allowedCharacters: '0123456789/-.\\',
        expectAmountAsInputValues: false,
      ),
    );
  }

  /// Builds the three-column input view with date, description, and amount
  Widget _buildInputFor3Columns() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: InputValues(
            title: 'Date',
            controller: _controllerColumn1,
            allowedCharacters: '0123456789/-.\\',
            expectAmountAsInputValues: false,
          ),
        ),
        Expanded(
          flex: 2,
          child: InputValues(
            title: 'Description',
            controller: _controllerColumn2,
            allowedCharacters: '',
            expectAmountAsInputValues: false,
          ),
        ),
        Expanded(
          flex: 1,
          child: InputValues(
            title: 'Amount',
            controller: _controllerColumn3,
            allowedCharacters:
                '0123456789,.()-+', // amounts like 12.34 12,34 1,234.56 1.234,56 +1.234,56 -1,234.56 (1,234.56)
            expectAmountAsInputValues: true,
          ),
        ),
      ],
    );
  }

  /// Converts single-column text into three columns
  void _fromOneToThreeColumn() {
    // Create parser with user preferences
    final ValuesParser parser = ValuesParser(
      dateFormat: widget.dateFormat,
      currency: widget.currency,
      reverseAmountValue: widget.reverseAmountValue,
    );

    // Parse the single column text and update individual columns
    parser.convertInputTextToTransactionList(
      context,
      _controllerSingleColumn.text,
    );

    _pauseTextSync = true;
    _controllerColumn1.text = parser.getListOfDatesString().join('\n');
    _controllerColumn2.text = parser.getListOfDescriptionString().join('\n');
    _controllerColumn3.text = parser.getListOfAmountString().join('\n');
    _pauseTextSync = false;
  }

  /// Combines three columns into a single text buffer
  String _fromThreeToOneColumn() {
    _controllerSingleColumn.text = _getSingleBufferWithLatest3ColumnsText();
    return _controllerSingleColumn.text;
  }

  /// Combines the content of all three columns into a single text string
  String _getSingleBufferWithLatest3ColumnsText() {
    return ValuesParser.assembleIntoSingleTextBuffer(
      _controllerColumn1.text,
      _controllerColumn2.text,
      _controllerColumn3.text,
    );
  }

  /// Notifies parent widget of changes through callback
  void _notifyChanged() {
    widget.onChanged(_controllerSingleColumn.text);
  }

  /// Sets up listeners for text changes in all three columns
  void _startListening() {
    _controllerColumn1.addListener(_syncText);
    _controllerColumn2.addListener(_syncText);
    _controllerColumn3.addListener(_syncText);
    _controllerSingleColumn.addListener(_syncText);
  }

  /// Removes text change listeners to prevent memory leaks
  void _stopListening() {
    _controllerColumn1.removeListener(_syncText);
    _controllerColumn2.removeListener(_syncText);
    _controllerColumn3.removeListener(_syncText);
    _controllerSingleColumn.removeListener(_syncText);
  }

  /// Synchronizes text between three-column and single-column views
  void _syncText() {
    _debouncer.run(() {
      if (_pauseTextSync) {
        return;
      }

      // Prevent recursive updates
      _pauseTextSync = true;

      // Update single column with combined content from three columns
      if (_freeStyleInput) {
        _updateAllTextControllerContentFromRawText(
          _controllerSingleColumn.text,
        );
      } else {
        _fromThreeToOneColumn();
      }
      _pauseTextSync = false;
      _notifyChanged();
    });
  }

  /// Updates all text controllers with initial or new input text
  void _updateAllTextControllerContentFromRawText(final String inputText) {
    _controllerSingleColumn.text = inputText;

    final ValuesParser parser = ValuesParser(
      dateFormat: widget.dateFormat,
      currency: widget.currency,
      reverseAmountValue: widget.reverseAmountValue,
    );

    if (context.mounted) {
      parser.convertInputTextToTransactionList(context, widget.inputText);

      _controllerColumn1.text = parser.getListOfDatesString().join('\n');
      _controllerColumn2.text = parser.getListOfDescriptionString().join('\n');
      _controllerColumn3.text = parser.getListOfAmountString().join('\n');
    }
  }
}
