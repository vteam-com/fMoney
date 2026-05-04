// ignore_for_file: always_put_control_body_on_new_line

import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:money/views/imports/formats/csv_import_view.dart';
import 'package:money/views/imports/formats/investment_csv_import_view.dart';
import 'package:money/views/imports/formats/qfx_import_view.dart';
import 'package:money/views/imports/shared/transactions_text_import_view.dart';
import 'package:path/path.dart' as path;

/// Returns the first file path whose extension is `.pdf`.
///
/// Searches through the provided file paths and returns the path of the first
/// file with a `.pdf` extension (case-insensitive). Returns `null` if no PDF
/// file is found.
String? pickFirstPdfPath(final List<String> filePaths) {
  for (final String filePath in filePaths) {
    if (path.extension(filePath).toLowerCase() == '.pdf') {
      return filePath;
    }
  }
  return null;
}

/// Checks if a dropped CSV file uses the supported investment CSV schema.
///
/// Reads the specified CSV file, parses its headers, and determines if the
/// headers match the investment CSV format (checking for required headers like
/// "Run Date", "Account Number", and "Amount").
///
/// Returns `true` if the file appears to be an investment CSV export,
/// `false` otherwise or if an error occurs during reading/parsing.
Future<bool> isInvestmentCSVFile(final String filePath) async {
  try {
    final File file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    final String csvContent = await file.readAsString();
    if (csvContent.trim().isEmpty) {
      return false;
    }

    final List<List<dynamic>> csvTable = const CsvDecoder(
      dynamicTyping: false,
    ).convert(csvContent);
    if (csvTable.isEmpty) {
      return false;
    }

    final List<String> headers = csvTable.first
        .map((final dynamic cell) => cell == null ? '' : cell.toString().trim())
        .cast<String>()
        .toList();
    if (headers.isNotEmpty) {
      headers[0] = headers[0].replaceFirst('\ufeff', '');
    }

    return isInvestmentCSV(headers);
  } catch (_) {
    return false;
  }
}

/// Handles dropped files by detecting their type and routing to appropriate importers.
///
/// This function processes a list of dropped file paths and routes each file to the
/// appropriate import handler based on file type detection:
/// - PDFs are handled first (if present) via PDF-to-AI import
/// - CSVs are auto-detected as either investment CSVs or generic CSVs
/// - Other supported formats (QFX) are routed to their respective importers
///
/// The [context] parameter must be mounted for the duration of the import operation.
/// If the context becomes unmounted during processing, the operation is aborted gracefully.
///
/// Example:
/// ```dart
/// DropZone(
///   onFilesDropped: (filePaths) => handleDroppedFiles(context, filePaths),
///   child: child,
/// )
/// ```
Future<void> handleDroppedFiles(
  final BuildContext context,
  final List<String> filePaths,
) async {
  final String? pdfPath = pickFirstPdfPath(filePaths);
  if (pdfPath != null) {
    unawaited(
      showImportTransactionsFromPdfUsingAi(
        context: context,
        pdfFilePath: pdfPath,
      ),
    );
    return;
  }

  unawaited(
    () async {
      for (final String filePath in filePaths) {
        final String extension = path.extension(filePath).toLowerCase();
        if (extension == '.csv') {
          final bool isInvCSV = await isInvestmentCSVFile(filePath);
          if (!context.mounted) {
            return;
          }
          if (isInvCSV) {
            await importInvestmentCSV(context, filePath);
          } else {
            await importCSV(context, filePath);
          }
        } else {
          await importQFX(context, filePath);
        }
      }
    }(),
  );
}
