import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_router.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/shared_strings.dart';
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
void onImportFromFile(final BuildContext context) async {
  final FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
    type: FileType.any,
  );
  if (pickerResult != null) {
    if (context.mounted) {
      switch (pickerResult.files.single.extension?.toLowerCase()) {
        case SharedStrings.fileExtensionQif:
          importQIF(context, pickerResult.files.single.path.toString());
          break; // Added break
        case SharedStrings.fileExtensionQfx:
          importQFX(context, pickerResult.files.single.path.toString());
          break; // Added break
        case SharedStrings.fileExtensionXlsx:
          importXLSX(context, pickerResult.files.single.path.toString());
          break;
        case SharedStrings.fileExtensionCsv:
          importCSV(context, pickerResult.files.single.path.toString());
          break;
      }
    }
  }
}
