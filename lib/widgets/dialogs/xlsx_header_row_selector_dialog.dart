import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';

const int _minHeaderColumnCount = 3;
const int _maxPreviewRows = 10;
const int _rowPreviewMaxLength = 100;
const int _rowNumberOffset = 1;
const double _previewSpacing = 10;
const double _footerTopPadding = 8;
const double _subtitleFontSize = 12;
const int _dateScoreWeight = 10;
const int _descriptionScoreWeight = 8;
const int _amountScoreWeight = 9;
const int _bonusAllTypes = 15;
const int _bonusDatePlusOne = 8;
const int _preferredColumnCountMin = 3;
const int _preferredColumnCountMax = 5;
const int _preferredColumnBonus = 5;

/// A stateful widget for xlsx header row selector dialog.
class XlsxHeaderRowSelectorDialog extends StatefulWidget {
  const XlsxHeaderRowSelectorDialog({
    super.key,
    required this.rows,
  });

  final List<List<String>> rows;

  @override
  State<XlsxHeaderRowSelectorDialog> createState() => _XlsxHeaderRowSelectorDialogState();
}

class _XlsxHeaderRowSelectorDialogState extends State<XlsxHeaderRowSelectorDialog> {
  late List<List<String>> _filteredRows;

  late List<int> _originalIndices;

  late int _selectedRowIndex;

  @override
  void initState() {
    super.initState();

    // Filter rows to only include those with 3 or more columns and track original indices
    _filteredRows = <List<String>>[];
    _originalIndices = <int>[];
    for (int i = 0; i < widget.rows.length; i++) {
      if (widget.rows[i].length >= _minHeaderColumnCount) {
        _filteredRows.add(widget.rows[i]);
        _originalIndices.add(i);
      }
    }

    // Find the best row to select by default (index in _filteredRows)
    final int filteredIndex = _findBestHeaderRowIndex(_filteredRows);
    // Convert to original index for return value
    _selectedRowIndex = filteredIndex >= 0 ? _originalIndices[filteredIndex] : -1;
    if (_selectedRowIndex < 0 && _originalIndices.isNotEmpty) {
      _selectedRowIndex = _originalIndices[0]; // Fallback to first available row
    }
  }

  @override
  Widget build(BuildContext context) {
    final int maxRowsToShow = _originalIndices.length > _maxPreviewRows ? _maxPreviewRows : _originalIndices.length;

    return AlertDialog(
      title: Text(AppL10n.tr(AppTranslationKeys.selectHeaderRow)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              AppL10n.tr(
                AppTranslationKeys.selectTheRowThatContainsTheColumnHeadersAutomaticallySelectedBasedOnContent,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: _previewSpacing),
            if (_originalIndices.isEmpty)
              Text(
                AppL10n.tr(AppTranslationKeys.noRowsFoundWith3OrMoreColumns),
                style: const TextStyle(fontStyle: FontStyle.italic),
              )
            else
              RadioGroup<int>(
                groupValue: _selectedRowIndex,
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _selectedRowIndex = value;
                    });
                  }
                },
                child: Column(
                  children: List<Widget>.generate(maxRowsToShow, (int index) {
                    final int originalIndex = _originalIndices[index];
                    final String rowPreview = widget.rows[originalIndex].join(' | ').length > _rowPreviewMaxLength
                        ? '${widget.rows[originalIndex].join(' | ').substring(0, _rowPreviewMaxLength)}...'
                        : widget.rows[originalIndex].join(' | ');
                    return RadioListTile<int>(
                      title: Text(
                        AppL10n.tr(
                          AppTranslationKeys.rowIndex,
                          params: <String, String>{
                            'index': (originalIndex + _rowNumberOffset).toString(),
                          },
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        rowPreview,
                        style: const TextStyle(fontSize: _subtitleFontSize),
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: originalIndex,
                    );
                  }),
                ),
              ),
            if (_originalIndices.length > _maxPreviewRows)
              Padding(
                padding: const EdgeInsets.only(top: _footerTopPadding),
                child: Text(
                  AppL10n.tr(
                    AppTranslationKeys.showingFirstMaxrowsOfRowcountEligibleRows,
                    params: <String, String>{
                      'maxRows': _maxPreviewRows.toString(),
                      'rowCount': _originalIndices.length.toString(),
                    },
                  ),
                  style: const TextStyle(
                    fontSize: _subtitleFontSize,
                    color: Colors.grey,
                  ),
                ),
              )
            else if (_originalIndices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: _footerTopPadding),
                child: Text(
                  AppL10n.tr(
                    AppTranslationKeys.showingRowcountEligibleRowsExcludedRowsWith3Columns,
                    params: <String, String>{
                      'rowCount': _originalIndices.length.toString(),
                    },
                  ),
                  style: const TextStyle(
                    fontSize: _subtitleFontSize,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppL10n.tr(AppTranslationKeys.cancel)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(_selectedRowIndex),
        ),
      ],
    );
  }

  /// Scores rows to find the most likely header row for financial data.
  int _findBestHeaderRowIndex(List<List<String>> rows) {
    if (rows.isEmpty) {
      return -1;
    }

    // Keywords for different column types (case insensitive)
    final Set<String> dateKeywords = <String>{'date', 'data', 'dia', 'fecha'};
    final Set<String> descriptionKeywords = <String>{'description', 'desc', 'memo', 'reference', 'details', 'detalhes'};
    final Set<String> amountKeywords = <String>{
      'amount',
      'valor',
      'value',
      'montante',
      'debit',
      'credit',
      'entrada',
      'saida',
      'saldo',
      'balance',
    };

    int bestIndex = -1;
    int highestScore = -1;

    for (int i = 0; i < rows.length; i++) {
      final List<String> row = rows[i];
      final List<String> headers = row.map((String cell) => cell.trim().toLowerCase()).toList();

      int score = 0;

      // Count matches for each type
      final int dateMatches = headers.where((String h) => dateKeywords.any((String k) => h.contains(k))).length;
      final int descMatches = headers.where((String h) => descriptionKeywords.any((String k) => h.contains(k))).length;
      final int amountMatches = headers.where((String h) => amountKeywords.any((String k) => h.contains(k))).length;

      // Score based on having matches for different types
      score += dateMatches * _dateScoreWeight;
      score += descMatches * _descriptionScoreWeight;
      score += amountMatches * _amountScoreWeight;

      // Bonus for having a good combination (date + description + amount/value)
      if (dateMatches > 0 && descMatches > 0 && amountMatches > 0) {
        score += _bonusAllTypes; // Significant bonus for having all three types
      } else if (dateMatches > 0 && (descMatches > 0 || amountMatches > 0)) {
        score += _bonusDatePlusOne; // Medium bonus for date plus at least one other type
      }

      // Prefer rows with 3-5 columns (typical for financial data)
      final int columnCount = row.length;
      if (columnCount >= _preferredColumnCountMin && columnCount <= _preferredColumnCountMax) {
        score += _preferredColumnBonus;
      }

      // Update best index if this row has higher score
      if (score > highestScore) {
        highestScore = score;
        bestIndex = i;
      }
    }

    return bestIndex;
  }
}

// Helper function to show the dialog
/// Shows a modal dialog for selecting the header row index from parsed XLSX rows.
Future<int?> showXlsxHeaderRowSelectorDialog({
  required BuildContext context,
  required List<List<String>> rows,
}) {
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext _) {
      return XlsxHeaderRowSelectorDialog(rows: rows);
    },
  );
}
