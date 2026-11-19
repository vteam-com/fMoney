import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';

const int _previewRowLimit = 5;
const double _columnHighlightAlpha = 0.5;
const double _cellHighlightAlpha = 0.2;
const double _previewSpacing = 20;
const double _dropdownVerticalPadding = 8.0;
const double _cellHorizontalPadding = 8;
const double _cellVerticalPadding = 4;
const int _exactHeaderMatchScoreBase = 1000;
const int _nonEmptyCellScoreWeight = 10;

// Header keywords shared with the XLSX header row picker, so the row it picks can be mapped here.

/// Header patterns for the Amount column, highest priority first; Portuguese and Spanish words come last.
/// A running balance is never an amount, so 'balance' and 'saldo' are intentionally absent.
const List<String> csvAmountColumnPatterns = <String>[
  'amount',
  'transaction amount',
  'value',
  'debit',
  'credit',
  'withdrawn',
  'withdrawal',
  'deposited',
  'deposit',
  'payment',
  'transfer amount',
  'charge',
  'fee',
  'cost',
  'price',
  'total',
  'valor',
  'montante',
  'entrada',
  'saida',
];

/// Header patterns for the Date column, highest priority first; Portuguese and Spanish words come last.
const List<String> csvDateColumnPatterns = <String>[
  'run date',
  'transaction date',
  'date',
  'posting date',
  'value date',
  'check date',
  'deposit date',
  'withdrawal date',
  'effective date',
  'processed date',
  'settlement date', // Last priority: often empty in investment exports
  'timestamp',
  'time',
  'data',
  'fecha',
  'dia',
];

/// Header patterns for the Description column, highest priority first; Portuguese and Spanish words come last.
const List<String> csvDescriptionColumnPatterns = <String>[
  'description',
  'transaction description',
  'action',
  'details',
  'memo',
  'reference',
  'payee',
  'vendor',
  'transaction',
  'narration',
  'remarks',
  'note',
  'comment',
  'merchant',
  'recipient',
  'supplier',
  'store',
  'desc',
  'detalhes',
];
const List<String> _quantityColumnPatterns = <String>[
  'quantity',
  'qty',
  'shares',
  'units',
  'amount of shares',
  'number of shares',
];
const List<String> _priceColumnPatterns = <String>[
  'price',
  'unit price',
  'share price',
  'value per share',
  'cost per share',
  'rate',
];

/// A stateful widget for csv column mapper dialog.
class CsvColumnMapperDialog extends StatefulWidget {
  const CsvColumnMapperDialog({
    super.key,
    required this.headers,
    required this.dataRows,
  });

  final List<List<String>> dataRows;

  final List<String> headers;

  /// Creates state for the column mapper dialog.
  @override
  State<CsvColumnMapperDialog> createState() => _CsvColumnMapperDialogState();
}

class _CsvColumnMapperDialogState extends State<CsvColumnMapperDialog> {
  String? _selectedAmountColumn;
  String? _selectedDateColumn;
  String? _selectedDescriptionColumn;
  String? _selectedPriceColumn;
  String? _selectedQuantityColumn;

  /// Unique identifiers for each header (handles duplicates)
  late final List<String> _uniqueIds;
  @override
  void initState() {
    super.initState();
    // Initialize unique header mappings
    _initializeUniqueHeaderMappings();
    // Auto-detect the best matching columns based on header names
    _autoDetectColumns();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.headers.isEmpty) {
      // Should not happen if CSV is valid and has headers
      return MyAlertDialog(
        title: AppL10n.tr(AppTranslationKeys.error),
        actions: <Widget>[
          TextButton(
            child: Text(AppL10n.tr(AppTranslationKeys.confirm)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: Text(AppL10n.tr(AppTranslationKeys.csvHeadersAreMissingOrEmpty)),
      );
    }

    return MyAlertDialog(
      title: AppL10n.tr(AppTranslationKeys.chooseColumns),
      actions: <Widget>[
        TextButton(
          child: Text(AppL10n.tr(AppTranslationKeys.cancel)),
          onPressed: () => Navigator.of(context).pop(), // No result means cancellation
        ),
        TextButton(
          child: Text(AppL10n.tr(AppTranslationKeys.confirm)),
          onPressed: () {
            // Validate selections (all are selected)
            if (_selectedDateColumn == null || _selectedDescriptionColumn == null || _selectedAmountColumn == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.pleaseMapAllFieldsDateDescriptionAmount))),
              );
              return;
            }
            // Return unique IDs (the header name unless duplicated); resolve them with [indexOfMappedColumn].
            final Map<String, String> mapping = <String, String>{
              'date': _selectedDateColumn!,
              'description': _selectedDescriptionColumn!,
              'amount': _selectedAmountColumn!,
            };

            // Add optional fields if selected
            if (_selectedQuantityColumn != null) {
              mapping['quantity'] = _selectedQuantityColumn!;
            }
            if (_selectedPriceColumn != null) {
              mapping['price'] = _selectedPriceColumn!;
            }

            Navigator.of(context).pop(mapping);
          },
        ),
      ],
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite, // Use available width
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildMappingDropdowns(),
              const SizedBox(height: _previewSpacing),
              Text(
                AppL10n.tr(AppTranslationKeys.dataPreviewFirst5Rows),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildPreviewTable(),
            ],
          ),
        ),
      ),
    );
  }

  /// Attempts to auto-select the most likely date/description/amount columns.
  void _autoDetectColumns() {
    if (widget.headers.isEmpty) {
      return;
    }

    // Find best matches for each required column type
    _selectedDateColumn = _findBestMatchUniqueId(csvDateColumnPatterns, preferNonEmptyCells: true);
    _selectedDescriptionColumn = _findBestMatchUniqueId(csvDescriptionColumnPatterns);
    _selectedAmountColumn = _findBestMatchUniqueId(csvAmountColumnPatterns);

    // Find best matches for optional columns
    _selectedQuantityColumn = _findBestMatchUniqueId(_quantityColumnPatterns);
    _selectedPriceColumn = _findBestMatchUniqueId(_priceColumnPatterns);
  }

  /// Builds a dropdown for selecting a unique header id for a required field.
  Widget _buildDropdown(String label, String? currentValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _dropdownVerticalPadding),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        initialValue: currentValue,
        hint: Text(AppL10n.tr(AppTranslationKeys.selectColumn)),
        isExpanded: true,
        items: _uniqueIds.map<DropdownMenuItem<String>>((String uniqueId) {
          return DropdownMenuItem<String>(
            value: uniqueId, // Use unique ID to prevent duplicate values
            child: Text(uniqueId), // Display the unique ID (with suffix if duplicated)
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  /// Builds the mapping dropdowns for date, description, amount, and optional quantity/price.
  Widget _buildMappingDropdowns() {
    final String quantityLabel =
        '${AppL10n.tr(AppTranslationKeys.quantity)} (${AppL10n.tr(AppTranslationKeys.optional)})';
    final String priceLabel = '${AppL10n.tr(AppTranslationKeys.price)} (${AppL10n.tr(AppTranslationKeys.optional)})';

    return Column(
      children: <Widget>[
        _buildDropdown(AppL10n.tr(AppTranslationKeys.date), _selectedDateColumn, (String? newValue) {
          setState(() {
            _selectedDateColumn = newValue;
          });
        }),
        _buildDropdown(AppL10n.tr(AppTranslationKeys.description), _selectedDescriptionColumn, (String? newValue) {
          setState(() {
            _selectedDescriptionColumn = newValue;
          });
        }),
        _buildDropdown(AppL10n.tr(AppTranslationKeys.amount), _selectedAmountColumn, (String? newValue) {
          setState(() {
            _selectedAmountColumn = newValue;
          });
        }),
        _buildDropdown(
          quantityLabel,
          _selectedQuantityColumn,
          (String? newValue) {
            setState(() {
              _selectedQuantityColumn = newValue;
            });
          },
        ),
        _buildDropdown(
          priceLabel,
          _selectedPriceColumn,
          (String? newValue) {
            setState(() {
              _selectedPriceColumn = newValue;
            });
          },
        ),
      ],
    );
  }

  /// Builds a preview table and highlights the currently selected columns.
  Widget _buildPreviewTable() {
    // Displaying only up to the first 5 data rows for preview
    final int previewRowCount = widget.dataRows.length > _previewRowLimit ? _previewRowLimit : widget.dataRows.length;
    if (previewRowCount == 0) {
      return Text(AppL10n.tr(AppTranslationKeys.noDataRowsToPreview));
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Use theme-aware colors that work in both light and dark modes
    final Color dateColumnColor = colorScheme.primary.withValues(alpha: _columnHighlightAlpha);
    final Color dateCellColor = colorScheme.primary.withValues(alpha: _cellHighlightAlpha);
    final Color descriptionColumnColor = colorScheme.secondary.withValues(alpha: _columnHighlightAlpha);
    final Color descriptionCellColor = colorScheme.secondary.withValues(alpha: _cellHighlightAlpha);
    final Color amountColumnColor = colorScheme.tertiary.withValues(alpha: _columnHighlightAlpha);
    final Color amountCellColor = colorScheme.tertiary.withValues(alpha: _cellHighlightAlpha);

    // Unique IDs are in header order, so their position is the column index
    final Map<String, int> uniqueIdToIndexMap = <String, int>{
      for (int i = 0; i < _uniqueIds.length; i++) _uniqueIds[i]: i,
    };

    // Find which columns are selected for highlighting using unique IDs
    final int? dateColumnIndex = _selectedDateColumn != null ? uniqueIdToIndexMap[_selectedDateColumn!] : null;
    final int? descriptionColumnIndex = _selectedDescriptionColumn != null
        ? uniqueIdToIndexMap[_selectedDescriptionColumn!]
        : null;
    final int? amountColumnIndex = _selectedAmountColumn != null ? uniqueIdToIndexMap[_selectedAmountColumn!] : null;

    return SingleChildScrollView(
      // Added SingleChildScrollView
      scrollDirection: Axis.horizontal, // Set to horizontal scroll
      child: DataTable(
        columns: List<DataColumn>.generate(widget.headers.length, (int headerIndex) {
          final String header = widget.headers[headerIndex];
          Color? columnColor;

          if (headerIndex == dateColumnIndex) {
            columnColor = dateColumnColor;
          } else if (headerIndex == descriptionColumnIndex) {
            columnColor = descriptionColumnColor;
          } else if (headerIndex == amountColumnIndex) {
            columnColor = amountColumnColor;
          }

          return DataColumn(
            label: Container(
              color: columnColor,
              padding: const EdgeInsets.symmetric(
                horizontal: _cellHorizontalPadding,
                vertical: _cellVerticalPadding,
              ),
              child: Text(header),
            ),
          );
        }),
        rows: widget.dataRows.sublist(0, previewRowCount).map((List<String> row) {
          final int numExpectedColumns = widget.headers.length;
          final List<DataCell> cells = <DataCell>[];
          for (int i = 0; i < numExpectedColumns; i++) {
            Color? cellColor;

            // Highlight the cells in selected columns
            if (i == dateColumnIndex) {
              cellColor = dateCellColor;
            } else if (i == descriptionColumnIndex) {
              cellColor = descriptionCellColor;
            } else if (i == amountColumnIndex) {
              cellColor = amountCellColor;
            }

            if (i < row.length) {
              cells.add(
                DataCell(
                  Container(
                    color: cellColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: _cellHorizontalPadding,
                      vertical: _cellVerticalPadding,
                    ),
                    child: Text(row[i]),
                  ),
                ),
              );
            } else {
              cells.add(
                DataCell(
                  Container(
                    color: cellColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: _cellHorizontalPadding,
                      vertical: _cellVerticalPadding,
                    ),
                    child: const Text(''),
                  ),
                ),
              );
            }
          }
          // If row.length > numExpectedColumns, extra cells in 'row' are implicitly truncated
          // because we only iterate up to numExpectedColumns.
          return DataRow(cells: cells);
        }).toList(),
      ), // End DataTable
    ); // End SingleChildScrollView
  }

  /// Finds the best matching unique header id for a list of expected patterns.
  String? _findBestMatchUniqueId(
    List<String> patterns, {
    bool preferNonEmptyCells = false,
  }) {
    final int bestIndex = findBestMatchingColumnIndex(
      headers: widget.headers,
      patterns: patterns,
      dataRows: widget.dataRows,
      preferNonEmptyCells: preferNonEmptyCells,
    );
    return bestIndex < 0 ? null : _uniqueIds[bestIndex];
  }

  /// Initializes mappings from potentially duplicated header names to unique ids.
  void _initializeUniqueHeaderMappings() {
    _uniqueIds = buildUniqueColumnIds(widget.headers);
  }
}

/// Returns one id per header: the header itself, or `Header (n)` for its n-th repeat.
List<String> buildUniqueColumnIds(List<String> headers) {
  final Map<String, int> headerCounts = <String, int>{};
  return headers.map((String header) {
    final int count = (headerCounts[header] ?? 0) + 1;
    headerCounts[header] = count;
    return count == 1 ? header : '$header ($count)';
  }).toList();
}

/// Returns the column index of [mappedId], a value returned by the column mapper
/// (a unique id, so duplicated headers resolve to their own column), or -1.
int indexOfMappedColumn(List<String> headers, String mappedId) {
  final int uniqueIndex = buildUniqueColumnIds(headers).indexOf(mappedId);
  return uniqueIndex >= 0 ? uniqueIndex : headers.indexOf(mappedId);
}

/// Returns the index of the header that best matches [patterns], or -1.
///
/// An exact match beats a partial (contains) match, and earlier patterns win
/// over later ones. With [preferNonEmptyCells], columns populated in the first
/// [dataRows] rank higher.
int findBestMatchingColumnIndex({
  required List<String> headers,
  required List<String> patterns,
  List<List<String>> dataRows = const <List<String>>[],
  bool preferNonEmptyCells = false,
}) {
  int bestScore = -1;
  int bestIndex = -1;

  for (int headerIndex = 0; headerIndex < headers.length; headerIndex++) {
    final String headerLower = headers[headerIndex].toLowerCase().trim();

    for (int patternIndex = 0; patternIndex < patterns.length; patternIndex++) {
      final String patternLower = patterns[patternIndex].toLowerCase();
      final int priority = patterns.length - patternIndex;
      int score = -1;

      if (headerLower == patternLower) {
        score = _exactHeaderMatchScoreBase + priority;
      } else if (headerLower.contains(patternLower)) {
        score = priority;
      }

      if (score < 0) {
        continue;
      }

      if (preferNonEmptyCells) {
        // Prefer populated columns over empty matches (e.g., Run Date over empty Settlement Date).
        score += _countNonEmptyValuesInColumn(dataRows, headerIndex) * _nonEmptyCellScoreWeight;
      }

      if (score > bestScore) {
        bestScore = score;
        bestIndex = headerIndex;
      }
    }
  }

  return bestIndex;
}

/// Counts non-empty values of [columnIndex] in the preview rows of [dataRows].
int _countNonEmptyValuesInColumn(List<List<String>> dataRows, int columnIndex) {
  int count = 0;
  final int previewRowCount = dataRows.length > _previewRowLimit ? _previewRowLimit : dataRows.length;
  for (int i = 0; i < previewRowCount; i++) {
    final List<String> row = dataRows[i];
    if (columnIndex < row.length && row[columnIndex].trim().isNotEmpty) {
      count++;
    }
  }
  return count;
}

// Helper function to show the dialog (optional, but good practice)
/// Shows the CSV column mapper dialog and returns the chosen mapping.
Future<Map<String, String>?> showCsvColumnMapperDialog({
  required BuildContext context,
  required List<String> headers,
  required List<List<String>> dataRows,
}) {
  return showDialog<Map<String, String>?>(
    context: context,
    barrierDismissible: false, // User must make a choice
    builder: (BuildContext _) {
      return CsvColumnMapperDialog(headers: headers, dataRows: dataRows);
    },
  );
}
