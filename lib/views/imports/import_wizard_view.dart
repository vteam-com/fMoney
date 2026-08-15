import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/views/imports/formats/csv_import_view.dart';
import 'package:money/views/imports/formats/investment_csv_import_view.dart';
import 'package:money/views/imports/formats/qfx_import_view.dart';
import 'package:money/views/imports/formats/qif_import_view.dart';
import 'package:money/views/imports/formats/xlsx_import_view.dart';
import 'package:money/views/imports/investment/investment_import_view.dart';
import 'package:money/views/imports/shared/transactions_text_import_view.dart';
import 'package:money/views/imports/transfer/transfer_import_view.dart';
import 'package:money/widgets/components/wizard_choice_widget.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:path/path.dart' as path;

const double _wizardSpacing = 40.0;

/// Supported file extensions accepted by the transaction import file picker.
const List<String> _supportedTransactionImportFileExtensions = <String>[
  SharedStrings.fileExtensionQfx,
  SharedStrings.fileExtensionQif,
  SharedStrings.fileExtensionXlsx,
  SharedStrings.fileExtensionCsv,
  SharedStrings.fileExtensionPdf,
];

/// Resolves the selected file extension from picker metadata or falls back to its path.
String _resolveSelectedFileExtension(PlatformFile file) {
  final String extensionFromMetadata = (file.extension ?? '').trim().toLowerCase();
  if (extensionFromMetadata.isNotEmpty) {
    return extensionFromMetadata.startsWith('.') ? extensionFromMetadata.substring(1) : extensionFromMetadata;
  }

  final String filePath = file.path ?? '';
  if (filePath.isEmpty) {
    return '';
  }

  final String extensionFromPath = path.extension(filePath).trim().toLowerCase();
  if (extensionFromPath.isEmpty) {
    return '';
  }
  return extensionFromPath.startsWith('.') ? extensionFromPath.substring(1) : extensionFromPath;
}

/// Checks if CSV file is an investment export by examining headers.
Future<bool> _isInvestmentCSVFile(String filePath) async {
  try {
    final File file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    final String csvContent = await file.readAsString();
    if (csvContent.trim().isEmpty) {
      return false;
    }

    // Parse first row to check headers
    final List<List<dynamic>> csvTable = const CsvDecoder(
      dynamicTyping: false,
    ).convert(csvContent);

    if (csvTable.isEmpty) {
      return false;
    }

    final List<String> headers = csvTable.first
        .map((dynamic cell) => cell == null ? '' : cell.toString().trim())
        .cast<String>()
        .toList();

    // Check for supported investment CSV headers
    return isInvestmentCSV(headers);
  } catch (_) {
    return false;
  }
}

/// Shows wizard dialog for importing transactions from various sources.
void showImportTransactionsWizard([BuildContext? context]) {
  final BuildContext originalContext = context ?? AppRouter.context!;

  adaptiveScreenSizeDialog(
    context: originalContext, // Use original context for showing the dialog
    captionForClose: AppL10n.tr(AppTranslationKeys.cancel),
    title: AppL10n.tr(AppTranslationKeys.importTransactions),
    child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: _wizardSpacing,
        children: <Widget>[
          gapMedium(),
          WizardChoice(
            title: AppL10n.tr(AppTranslationKeys.importFromQfxQifXlsxCsvFile),
            description: AppL10n.tr(AppTranslationKeys.importFromQfxQifXlsxCsvDescription),
            onPressed: () {
              Navigator.of(originalContext).pop(true); // Use originalContext
              onImportFromFile(originalContext); // Pass original, still-mounted context
            },
          ),
          WizardChoice(
            title: AppL10n.tr(AppTranslationKeys.manualBulkTextInput),
            description: AppL10n.tr(AppTranslationKeys.manualBulkTextInputDescription),
            onPressed: () {
              Navigator.of(originalContext).pop(true); // Use originalContext
              showImportTransactionsFromTextInput(originalContext); // Use originalContext
            },
          ),
          WizardChoice(
            title: AppL10n.tr(AppTranslationKeys.recordTransfer),
            description: AppL10n.tr(AppTranslationKeys.addTransactionBetweenTwoAccounts),
            onPressed: () {
              Navigator.of(originalContext).pop(true); // Use originalContext
              showImportTransfer();
            },
          ),
          WizardChoice(
            title: AppL10n.tr(AppTranslationKeys.investmentTransaction),
            description: AppL10n.tr(AppTranslationKeys.buySellDividend),
            onPressed: () {
              Navigator.of(originalContext).pop(true); // Use originalContext
              showImportInvestment();
            },
          ),
        ],
      ),
    ),
  );
}

/// Handles file selection and import from chosen file.
Future<void> onImportFromFile(BuildContext context) async {
  final FilePickerResult? pickerResult = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: _supportedTransactionImportFileExtensions,
  );
  if (pickerResult == null || !context.mounted) {
    return;
  }

  final PlatformFile file = pickerResult.files.single;
  final String? filePath = file.path;
  if (filePath == null || filePath.isEmpty) {
    return;
  }

  final String fileExtension = _resolveSelectedFileExtension(file);
  switch (fileExtension) {
    case SharedStrings.fileExtensionQif:
      importQIF(context, filePath);
      break;
    case SharedStrings.fileExtensionQfx:
      importQFX(context, filePath);
      break;
    case SharedStrings.fileExtensionXlsx:
      importXLSX(context, filePath);
      break;
    case SharedStrings.fileExtensionCsv:
      // Check if this is an investment CSV export
      if (context.mounted) {
        final bool isInvestmentCSVFile = await _isInvestmentCSVFile(filePath);
        if (context.mounted) {
          if (isInvestmentCSVFile) {
            importInvestmentCSV(context, filePath);
          } else {
            importCSV(context, filePath);
          }
        }
      }
      break;
    case SharedStrings.fileExtensionPdf:
      await showImportTransactionsFromPdfUsingAi(
        context: context,
        pdfFilePath: filePath,
      );
      break;
  }
}
