import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';

const int _previewRowLimit = 5;
const double _columnHighlightAlpha = 0.5;
const double _cellHighlightAlpha = 0.2;
const double _previewSpacing = 20;
const double _dropdownVerticalPadding = 8.0;
const double _cellHorizontalPadding = 8;
const double _cellVerticalPadding = 4;
const List<String> _amountColumnPatterns = <String>[
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
  'balance',
  'charge',
  'fee',
  'cost',
  'price',
  'total',
];
const List<String> _dateColumnPatterns = <String>[
  'date',
  'transaction date',
  'posting date',
  'value date',
  'check date',
  'deposit date',
  'withdrawal date',
  'transfer date',
  'settlement date',
  'effective date',
  'processed date',
  'timestamp',
  'time',
];
const List<String> _descriptionColumnPatterns = <String>[
  'description',
  'transaction description',
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

  /// Map from unique identifier to display name
  late final Map<String, String> _uniqueIdToHeaderName;

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
      return AlertDialog(
        title: Text(AppL10n.tr(AppTranslationKeys.error)), // Keep inner Text const if possible
        content: Text(AppL10n.tr(AppTranslationKeys.csvHeadersAreMissingOrEmpty)), // Keep inner Text const
        actions: <Widget>[
          TextButton(
            child: Text(AppL10n.tr(AppTranslationKeys.confirm)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(AppL10n.tr(AppTranslationKeys.chooseColumns)),
      content: SingleChildScrollView(
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
            // Convert unique IDs back to original header names for the result
            final String dateHeader = _uniqueIdToHeaderName[_selectedDateColumn!] ?? _selectedDateColumn!;
            final String descriptionHeader =
                _uniqueIdToHeaderName[_selectedDescriptionColumn!] ?? _selectedDescriptionColumn!;
            final String amountHeader = _uniqueIdToHeaderName[_selectedAmountColumn!] ?? _selectedAmountColumn!;

            final Map<String, String> mapping = <String, String>{
              'date': dateHeader,
              'description': descriptionHeader,
              'amount': amountHeader,
            };
            Navigator.of(context).pop(mapping);
          },
        ),
      ],
    );
  }

  /// Attempts to auto-select the most likely date/description/amount columns.
  void _autoDetectColumns() {
    if (widget.headers.isEmpty) {
      return;
    }

    // Find best matches for each required column type
    _selectedDateColumn = _findBestMatchUniqueId(_dateColumnPatterns);
    _selectedDescriptionColumn = _findBestMatchUniqueId(_descriptionColumnPatterns);
    _selectedAmountColumn = _findBestMatchUniqueId(_amountColumnPatterns);
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

  /// Builds the mapping dropdowns for date, description, and amount.
  Widget _buildMappingDropdowns() {
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

    // Create inverse map to find which header indices correspond to selected unique IDs
    final Map<String, int> uniqueIdToIndexMap = <String, int>{};

    // Build the complete mapping from unique IDs to indices using header positions
    // Since headers may have duplicates, we need to find the correct position for each unique ID
    final Map<String, int> headerNameUsageCount = <String, int>{};

    for (int headerIndex = 0; headerIndex < widget.headers.length; headerIndex++) {
      final String headerName = widget.headers[headerIndex];
      final int usageCount = headerNameUsageCount[headerName] ?? 0;

      // Find the matching unique ID based on usage count
      final String uniqueId;
      if (usageCount == 0) {
        uniqueId = headerName;
      } else {
        uniqueId = '$headerName (${usageCount + 1})';
      }

      // Verify this uniqueId exists in our mapping
      if (_uniqueIdToHeaderName.containsKey(uniqueId) && _uniqueIdToHeaderName[uniqueId] == headerName) {
        uniqueIdToIndexMap[uniqueId] = headerIndex;
      }

      headerNameUsageCount[headerName] = usageCount + 1;
    }

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

  /// Finds the best matching header name for a list of expected patterns.
  String? _findBestMatch(List<String> patterns) {
    if (patterns.isEmpty) {
      return null;
    }

    int bestScore = 0;
    String? bestMatch;

    for (final String header in widget.headers) {
      final String headerLower = header.toLowerCase().trim();

      for (final String pattern in patterns) {
        final String patternLower = pattern.toLowerCase();

        // Exact match gets highest score
        if (headerLower == patternLower) {
          return header; // Perfect match, return immediately
        }

        // Contains pattern gets points
        if (headerLower.contains(patternLower)) {
          final int score = patternLower.length; // Longer patterns get more points
          if (score > bestScore) {
            bestScore = score;
            bestMatch = header;
          }
        }
      }
    }

    return bestMatch;
  }

  /// Finds the best matching unique header id for a list of expected patterns.
  String? _findBestMatchUniqueId(List<String> patterns) {
    final String? bestHeader = _findBestMatch(patterns);
    if (bestHeader == null) {
      return null;
    }

    // Find the corresponding unique ID
    return _uniqueIdToHeaderName.keys.firstWhere(
      (String uniqueId) => _uniqueIdToHeaderName[uniqueId] == bestHeader,
      orElse: () => bestHeader, // Fallback to just the header if not found (though this shouldn't happen)
    );
  }

  /// Initializes mappings from potentially duplicated header names to unique ids.
  void _initializeUniqueHeaderMappings() {
    _uniqueIdToHeaderName = <String, String>{};
    final Map<String, int> headerCounts = <String, int>{};

    for (int i = 0; i < widget.headers.length; i++) {
      final String header = widget.headers[i];
      final String uniqueId;

      if (headerCounts.containsKey(header)) {
        // Duplicate header, add index to make it unique
        final int count = headerCounts[header]! + 1;
        headerCounts[header] = count;
        uniqueId = '$header ($count)';
      } else {
        headerCounts[header] = 1;
        uniqueId = header;
      }

      _uniqueIdToHeaderName[uniqueId] = header;
    }

    _uniqueIds = _uniqueIdToHeaderName.keys.toList();
  }
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
