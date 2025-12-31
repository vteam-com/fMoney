// ignore_for_file: always_put_control_body_on_new_line

import 'dart:io'; // For File operations

import 'package:flutter/material.dart'; // For BuildContext and other UI elements
import 'package:money/data/storage/import/import_data.dart';
import 'package:money/widgets/csv_column_mapper_dialog.dart'; // Import the dialog
// TODO: Replace print calls with a proper logging utility.

Future<void> importCSV(BuildContext context, String filePath) async {
  // print('importCSV called with filePath: $filePath'); // Removed
  try {
    final File file = File(filePath);
    final List<String> lines = await file.readAsLines();

    if (!context.mounted) return; // Guard after await

    if (lines.isEmpty) {
      // print('CSV file is empty.'); // Removed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV file is empty.')),
      );
      return;
    }

    final List<String> headers = lines.first.split(',');
    final List<List<String>> dataRows = lines.skip(1).map((String line) => line.split(',')).toList();
    final List<List<String>> previewRows = dataRows.length > 5 ? dataRows.sublist(0, 5) : dataRows;

    if (!context.mounted) {
      // print("Context is not mounted, cannot show dialog."); // Removed
      return;
    }

    final Map<String, String>? columnMapping = await showCsvColumnMapperDialog(
      context: context,
      headers: headers,
      dataRows: previewRows,
    );

    if (!context.mounted) {
      return;
    } // Guard after await

    if (columnMapping != null) {
      // print('Column mapping received: $columnMapping'); // Removed
      final ImportData importData = loadCSV(headers, dataRows, columnMapping);

      if (importData.entries.isNotEmpty) {
        showAndConfirmTransactionToImport(context, importData);
      } else {
        // print('No entries to import after processing CSV.'); // Removed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid entries found in CSV to import.')),
          );
        }
      }
    } else {
      // print('CSV import cancelled by user.'); // Removed
      if (context.mounted) {
        // Added guard, though SnackBar is after pop, original context should be fine.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV import cancelled.')),
        );
      }
    }
  } catch (e) {
    // print('Error importing CSV: $e'); // Removed
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing CSV: $e')),
      );
    }
  }
}

ImportData loadCSV(
  List<String> headers,
  List<List<String>> dataRows,
  Map<String, String> columnMapping,
) {
  final ImportData importData = ImportData();
  importData.fileType = 'CSV';

  final String dateColumnName = columnMapping['date']!;
  final String descriptionColumnName = columnMapping['description']!;
  final String amountColumnName = columnMapping['amount']!;

  final int dateIndex = headers.indexOf(dateColumnName);
  final int descriptionIndex = headers.indexOf(descriptionColumnName);
  final int amountIndex = headers.indexOf(amountColumnName);

  if (dateIndex == -1 || descriptionIndex == -1 || amountIndex == -1) {
    // print('Error: One or more mapped column names not found in CSV headers.'); // Removed
    // TODO: Communicate this error more formally (e.g., throw exception, return error status)
    return importData;
  }

  for (int i = 0; i < dataRows.length; i++) {
    final List<String> row = dataRows[i];

    final int maxIndex = <int>[dateIndex, descriptionIndex, amountIndex].reduce((int a, int b) => a > b ? a : b);
    if (row.length <= maxIndex) {
      // print('Skipping row ${i + 1}: Not enough columns for mapped fields. Row: "${row.join(",")}"'); // Removed
      // TODO: Log skipped row
      continue;
    }

    DateTime? date;
    try {
      date = DateTime.parse(row[dateIndex].trim());
    } catch (e) {
      // print('Skipping row ${i + 1}: Invalid date format for "${row[dateIndex].trim()}". Error: $e. Row: "${row.join(",")}"'); // Removed
      // TODO: Log skipped row with error
      continue;
    }

    final String description = row[descriptionIndex].trim();
    if (description.isEmpty) {
      // print('Skipping row ${i + 1}: Description is empty. Row: "${row.join(",")}"'); // Removed
      // TODO: Log skipped row
      continue;
    }

    double? amount;
    try {
      amount = double.tryParse(row[amountIndex].trim());
      if (amount == null) {
        // print('Skipping row ${i + 1}: Amount "${row[amountIndex].trim()}" is not a valid number. Row: "${row.join(",")}"'); // Removed
        // TODO: Log skipped row
        continue;
      }
    } catch (e) {
      // print('Skipping row ${i + 1}: Error parsing amount for "${row[amountIndex].trim()}". Error: $e. Row: "${row.join(",")}"'); // Removed
      // TODO: Log skipped row with error
      continue;
    }

    importData.entries.add(
      ImportEntry(
        date: date,
        name: description,
        amount: amount,
        type: 'CSVImport',
        fitid: 'csv_row_${i + 1}_${date.millisecondsSinceEpoch}',
        memo: '',
        number: '',
        stockAction: '',
        stockSymbol: '',
        stockQuantity: 0.0,
        stockPrice: 0.0,
        stockCommission: 0.0,
      ),
    );
  }
  // print('loadCSV processed ${dataRows.length} data rows, successfully created ${importData.entries.length} entries.'); // Removed
  // TODO: Log processing summary
  return importData;
}
