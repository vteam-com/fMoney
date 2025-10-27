import 'package:flutter/material.dart';

class CsvColumnMapperDialog extends StatefulWidget {
  const CsvColumnMapperDialog({
    super.key,
    required this.headers,
    required this.dataRows,
  });

  final List<List<String>> dataRows;

  final List<String> headers;

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

  void _autoDetectColumns() {
    if (widget.headers.isEmpty) {
      return;
    }

    // Find best matches for each required column type
    _selectedDateColumn = _findBestMatchUniqueId(_getDateColumnPatterns());
    _selectedDescriptionColumn = _findBestMatchUniqueId(_getDescriptionColumnPatterns());
    _selectedAmountColumn = _findBestMatchUniqueId(_getAmountColumnPatterns());
  }

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

  List<String> _getDateColumnPatterns() {
    return <String>[
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
  }

  List<String> _getDescriptionColumnPatterns() {
    return <String>[
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
  }

  List<String> _getAmountColumnPatterns() {
    return <String>[
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
  }

  @override
  Widget build(BuildContext context) {
    if (widget.headers.isEmpty) {
      // Should not happen if CSV is valid and has headers
      return AlertDialog(
        title: const Text('Error'), // Keep inner Text const if possible
        content: const Text('CSV headers are missing or empty.'), // Keep inner Text const
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Choose Columns'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite, // Use available width
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildMappingDropdowns(),
              const SizedBox(height: 20),
              const Text('Data Preview (First 5 rows):', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildPreviewTable(),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(), // No result means cancellation
        ),
        TextButton(
          child: const Text('Confirm'),
          onPressed: () {
            // Validate selections (all are selected)
            if (_selectedDateColumn == null || _selectedDescriptionColumn == null || _selectedAmountColumn == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please map all fields (Date, Description, Amount).')),
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

  Widget _buildDropdown(String label, String? currentValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        initialValue: currentValue,
        hint: const Text('Select column'),
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

  Widget _buildMappingDropdowns() {
    return Column(
      children: <Widget>[
        _buildDropdown('Date Column:', _selectedDateColumn, (String? newValue) {
          setState(() {
            _selectedDateColumn = newValue;
          });
        }),
        _buildDropdown('Description Column:', _selectedDescriptionColumn, (String? newValue) {
          setState(() {
            _selectedDescriptionColumn = newValue;
          });
        }),
        _buildDropdown('Amount Column:', _selectedAmountColumn, (String? newValue) {
          setState(() {
            _selectedAmountColumn = newValue;
          });
        }),
      ],
    );
  }

  Widget _buildPreviewTable() {
    // Displaying only up to the first 5 data rows for preview
    final int previewRowCount = widget.dataRows.length > 5 ? 5 : widget.dataRows.length;
    if (previewRowCount == 0) {
      return const Text('No data rows to preview.');
    }

    return SingleChildScrollView(
      // Added SingleChildScrollView
      scrollDirection: Axis.horizontal, // Set to horizontal scroll
      child: DataTable(
        columns: widget.headers.map((String header) => DataColumn(label: Text(header))).toList(),
        rows: widget.dataRows.sublist(0, previewRowCount).map((List<String> row) {
          final int numExpectedColumns = widget.headers.length;
          final List<DataCell> cells = <DataCell>[];
          for (int i = 0; i < numExpectedColumns; i++) {
            if (i < row.length) {
              cells.add(DataCell(Text(row[i]))); // Cell exists
            } else {
              cells.add(const DataCell(Text(''))); // Pad with empty cell
            }
          }
          // If row.length > numExpectedColumns, extra cells in 'row' are implicitly truncated
          // because we only iterate up to numExpectedColumns.
          return DataRow(cells: cells);
        }).toList(),
      ), // End DataTable
    ); // End SingleChildScrollView
  }
}

// Helper function to show the dialog (optional, but good practice)
Future<Map<String, String>?> showCsvColumnMapperDialog({
  required BuildContext context,
  required List<String> headers,
  required List<List<String>> dataRows,
}) {
  return showDialog<Map<String, String>?>(
    context: context,
    barrierDismissible: false, // User must make a choice
    builder: (BuildContext context) {
      return CsvColumnMapperDialog(headers: headers, dataRows: dataRows);
    },
  );
}
