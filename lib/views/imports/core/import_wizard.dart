import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/app_router.dart';
import 'package:money/views/imports/core/import_csv.dart';
import 'package:money/views/imports/core/import_investment.dart';
import 'package:money/views/imports/core/import_qfx.dart';
import 'package:money/views/imports/core/import_qif.dart';
import 'package:money/views/imports/core/import_transactions_from_text.dart';
import 'package:money/views/imports/core/import_transfer.dart';
import 'package:money/views/imports/core/import_xlsx.dart';
import 'package:money/widgets/components/wizard_choice.dart';
import 'package:money/widgets/dialogs/dialog.dart';
import 'package:money/widgets/pure/gaps.dart';

const double _wizardSpacing = 40.0;

/// Shows wizard dialog for importing transactions from various sources.
void showImportTransactionsWizard([BuildContext? context]) {
  final BuildContext originalContext = context ?? AppRouter.context!;

  adaptiveScreenSizeDialog(
    context: originalContext, // Use original context for showing the dialog
    captionForClose: 'Cancel',
    title: 'Import transactions',
    child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: _wizardSpacing,
        children: <Widget>[
          gapMedium(),
          WizardChoice(
            title: 'From QFX|QIF|XLSX|CSV file', // Changed title
            description: 'Import transactions from a QFX, QIF, XLSX, or CSV file.', // Changed description
            onPressed: () {
              Navigator.of(originalContext).pop(true); // Use originalContext
              onImportFromFile(originalContext); // Pass original, still-mounted context
            },
          ),
          WizardChoice(
            title: 'Manual bulk text input',
            description:
                'Refer to your online statements, then Copy & Paste text or use OCR to extract the [Dates | Memos | Amounts].',
            onPressed: () {
              Navigator.of(originalContext).pop(true); // Use originalContext
              showImportTransactionsFromTextInput(originalContext); // Use originalContext
            },
          ),
          WizardChoice(
            title: 'Record a transfer',
            description: 'add a transaction Between two accounts.',
            onPressed: () {
              Navigator.of(originalContext).pop(true); // Use originalContext
              showImportTransfer();
            },
          ),
          WizardChoice(
            title: 'Investment Transaction',
            description: 'Buy/Sell/Dividend.',
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
void onImportFromFile(final BuildContext context) async {
  final FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
    type: FileType.any,
  );
  if (pickerResult != null) {
    if (context.mounted) {
      switch (pickerResult.files.single.extension?.toLowerCase()) {
        case 'qif':
          importQIF(context, pickerResult.files.single.path.toString());
          break; // Added break
        case 'qfx':
          importQFX(context, pickerResult.files.single.path.toString());
          break; // Added break
        case 'xlsx': // XLSX import
          importXLSX(context, pickerResult.files.single.path.toString());
          break;
        case 'csv': // Added csv case
          importCSV(context, pickerResult.files.single.path.toString());
          break;
      }
    }
  }
}
