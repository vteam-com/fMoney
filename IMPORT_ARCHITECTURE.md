# fMoney Import Architecture

## Overview

fMoney supports importing financial data from multiple file formats: **CSV, QIF, QFX, XLSX, and PDF**. The architecture uses a format-specific strategy pattern with a common `ImportData` data structure.

---

## 1. Core Data Models

### Transaction Entity

**Location:** [lib/shared/domain/transaction_entity.dart](lib/shared/domain/transaction_entity.dart)

```dart
class Transaction extends DataObject implements MergeableItem {
  // Core fields
  late FieldAccountId        // Account this transaction belongs to
  late FieldMoney fieldAmount
  late FieldDateTime fieldDateTime
  late FieldString fieldMemo
  late FieldString fieldNumber
  late FieldPayee fieldPayee (ID reference)
  late FieldCategoryId fieldCategoryId
  late FieldStatus fieldStatus (none, electronic, cleared, reconciled, voided)
  late FieldString fieldFitid  // Financial Institution Transaction ID
  late FieldTransfer fieldTransfer
  late FieldFlags fieldFlags
  
  // Factory constructors:
  - fromJSon(MyJson json, runningBalance)
  - fromDateDescriptionAmount(account, date, description, amount)
}
```

Key features:

- Status tracking: `TransactionStatus.{ none, electronic, cleared, reconciled, voided }`
- Support for splits via `TransactionSplit`
- Supports investment transactions with stock symbols, quantities, prices
- FITID (Financial Institution Transaction ID) for de-duplication
- Transfer support for inter-account transactions

### Account Entity

**Location:** [lib/shared/domain/account_entity.dart](lib/shared/domain/account_entity.dart)

```dart
class Account extends DataObject {
  late FieldString fieldAccountId      // Unique account identifier
  late FieldString fieldOfxAccountId   // OFX-specific ID
  late FieldString fieldName
  late FieldString fieldDescription
  late FieldType fieldType             // AccountType enum: Bank, CreditCard, etc.
  late FieldMoney fieldOpeningBalance
  late FieldString fieldCurrency
  late FieldOnlineAccount fieldOnlineAccount  // ID reference
  late FieldLastSync fieldLastSync
  late FieldString fieldSyncGuid
  
  // Factory constructor
  factory Account.fromJson(MyJson row)
}
```

Supported account types: `Bank, CreditCard, Investment, Loan, Rental, etc.`

---

## 2. Import Data Structure

**Location:** [lib/views/imports/shared/data_import_view.dart](lib/views/imports/shared/data_import_view.dart)

### ImportData Class

```dart
class ImportData {
  List<ImportEntry> entries              // Parsed transaction entries ready for import
  String fileType                         // 'CSV', 'QIF', 'QFX', 'XLSX', 'PDF'
  Account? account                        // Optional: pre-selected destination account
  AccountType? accountType                // Optional: account type hint
  ImportDiagnostics diagnostics          // Parse statistics and skip reasons
}
```

### ImportEntry Class

```dart
class ImportEntry {
  late double amount
  late DateTime date
  late String fitid                       // Financial Institution Transaction ID
  late String memo
  late String name                        // Primary description field
  late String number                      // Check/reference number
  late String type                        // Transaction type (e.g., 'DEBIT', 'CREDIT')
  
  // Investment-specific fields
  late String stockAction                 // 'BUY', 'SELL', 'DIVIDEND', etc.
  late double stockCommission
  late double stockPrice
  late double stockQuantity
  late String stockSymbol
  
  factory ImportEntry.blank()
  String getDescription()                 // Returns name || memo || stock description
}
```

### ImportDiagnostics Class

```dart
class ImportDiagnostics {
  int processedRows                       // Total source rows examined
  int skippedRows                         // Total rows skipped
  Map<String, int> skippedByReason        // Breakdown by skip reason
  
  void incrementSkipped(String reasonKey)
}
```

**Skip Reasons Used:**

- `'missingMappedColumns'` - Column mapping incomplete
- `'insufficientColumns'` - Not enough columns for required fields
- `'invalidDate'` - Date parsing failed
- `'emptyDescription'` - Missing transaction name/memo
- `'invalidAmount'` - Amount parsing failed
- `'missingRequiredMapping'` - Required field not mapped

---

## 3. Import Strategy Architecture

### Format Dispatch Pattern

**Location:** [lib/views/imports/import_wizard_view.dart](lib/views/imports/import_wizard_view.dart)

The `onImportFromFile()` function uses a **switch-case dispatch pattern** to route by file extension:

```dart
final String fileExtension = _resolveSelectedFileExtension(file);
switch (fileExtension) {
  case SharedStrings.fileExtensionQif:
    importQIF(context, filePath);
  case SharedStrings.fileExtensionQfx:
    importQFX(context, filePath);
  case SharedStrings.fileExtensionXlsx:
    importXLSX(context, filePath);
  case SharedStrings.fileExtensionCsv:
    importCSV(context, filePath);
  case SharedStrings.fileExtensionPdf:
    await showImportTransactionsFromPdfUsingAi(
      context: context,
      pdfFilePath: filePath,
    );
}
```

**Supported file extensions:**

- `.qif` → QIF (Quicken Interchange Format)
- `.qfx` → QFX (Open Financial Exchange)
- `.xlsx` → XLSX (Excel)
- `.csv` → CSV (Comma-Separated Values)
- `.pdf` → PDF (AI-extracted bank statements)

---

## 4. Format-Specific Loaders

Each format has its own loader function that parses raw file content and returns `ImportData`:

### CSV Import

**Location:** [lib/views/imports/formats/csv_import_view.dart](lib/views/imports/formats/csv_import_view.dart)

```dart
Future<void> importCSV(BuildContext context, String filePath)
CsvRowsData parseCsvContent(String csvContent)
ImportData loadCSV(List<String> headers, List<List<String>> dataRows, Map<String, String> columnMapping)
```

- Uses `csv` package with `CsvDecoder`
- Displays **CSV Column Mapper Dialog** for user to map headers to transaction fields
- Supports RFC-compatible CSV parsing
- **Skip Reasons:** Missing mappings, invalid dates, empty descriptions, invalid amounts

**Key Fields Mapped:**

- `date` - Transaction date (required)
- `amount` - Transaction amount (required)
- `description` / `name` - Transaction description (required)
- `memo` - Optional transaction notes
- `number` - Check/reference number (optional)

### QIF Import

**Location:** [lib/views/imports/formats/qif_import_view.dart](lib/views/imports/formats/qif_import_view.dart)

```dart
void importQIF(BuildContext context, String filePath)
ImportData loadQIF(List<String> lines)
```

- **Schema:** <https://www.w3.org/2000/10/swap/pim/qif-doc/QIF-doc.htm>
- Uses field-based parsing with single-letter indicators (`D` = Date, `T` = Amount, `M` = Memo, `^` = End of transaction)
- Supports investment transactions (`!Type:Invst`)
- Handles date formats with `'` as separator (e.g., `01/30'2000`)
- Uses `DateFormat('MM/dd/yyyy')` for parsing

**QIF Field Codes:**

- `D` = Date
- `T` = Amount (or `$` as alternative)
- `M` = Memo
- `!` = Account type header
- `^` = End of transaction marker

### QFX Import

**Location:** [lib/views/imports/formats/qfx_import_view.dart](lib/views/imports/formats/qfx_import_view.dart)

```dart
Future<bool> importQFX(BuildContext context, String filePath)
void importQfxFromString(BuildContext? context, String text)
class OfxBankInfo
List<ImportEntry> getTransactionFromOFX(String ofx)
```

- **Format:** OFX/XML-based financial data exchange
- Parses `<OFX>...</OFX>` delimited content
- Extracts bank info: Account ID, Account Type, Bank ID
- Auto-detects destination account using `Data().accounts.findByIdAndType()`
- Supports both bank and investment accounts

**OFX Tags Parsed:**

- `<BANKID>` - Bank identifier
- `<ACCTID>` - Account ID
- `<ACCTTYPE>` - Account type (e.g., SAVINGS, CHECKING)

### XLSX Import

**Location:** [lib/views/imports/formats/xlsx_import_view.dart](lib/views/imports/formats/xlsx_import_view.dart)

```dart
Future<void> importXLSX(BuildContext context, String filePath)
ImportData loadXLSX(List<String> headers, List<List<String>> dataRows, Map<String, String> columnMapping)
```

- **Dependencies:** `archive` package for ZIP extraction
- Simple, dependency-free XLSX parser (single sheet, static values only)
- Extracts `xl/sharedStrings.xml` for shared string values
- Regex-based XML parsing: `<(?:\w+:)?t[^>]*>(.*?)</(?:\w+:)?t>`
- Excel date handling (OLE automation dates: base year 1899-12-30)
- Shows **Header Row Selector Dialog** if multiple candidate header rows detected
- Then shows **Column Mapper Dialog** like CSV

**Excel Date Conversion:**

- Base date: 1899-12-30 (OLE automation epoch)
- Range check: 20000 ≤ date serial ≤ 60000

### PDF Import (AI-Powered)

**Location:** [lib/views/imports/shared/ai_pdf_import_service.dart](lib/views/imports/shared/ai_pdf_import_service.dart)

```dart
class AiPdfImportService {
  Future<BankStatementParseResult> parsePdfStatement({required String filePath})
}
```

- Uses **Ollama** (local AI) for intelligent transaction extraction
- Fallback heuristic parsing if AI unavailable
- Extracts account hints from PDF text
- Text extraction limit: 45,000 characters for Ollama
- Returns `BankStatementParseResult` with detected currency code

---

## 5. Common UI Workflows

### CSV Column Mapper Dialog

**Location:** [lib/widgets/dialogs/csv_column_mapper_dialog.dart](lib/widgets/dialogs/csv_column_mapper_dialog.dart)

```dart
Map<String, String>? showCsvColumnMapperDialog(
  BuildContext context,
  List<String> headers,
  List<List<String>> previewRows,
)
```

- Shows preview of first 5 data rows
- User selects which CSV column maps to each transaction field
- Returns `Map<String, String>` mapping header → field name
- Returns `null` if user cancels

### Import Preview & Confirmation

**Location:** [lib/views/imports/shared/data_import_view.dart](lib/views/imports/shared/data_import_view.dart)

```dart
void showAndConfirmTransactionToImport(
  BuildContext context,
  ImportData importData,
)
```

- If no account selected, shows account picker
- Displays transaction list preview in `ImportTransactionsListPreview`
- User confirms or cancels bulk import
- Shows diagnostics: "CSV import parsed X entries and skipped Y rows"

---

## 6. Import Type Registration

### Main Import Wizard

**Location:** [lib/views/imports/import_wizard_view.dart](lib/views/imports/import_wizard_view.dart#L54-L105)

The main import wizard offers these entry points:

```text
1. "From QFX|QIF|XLSX|CSV|PDF file"
   ↓ onImportFromFile() → dispatch by extension
   
2. "Manual Bulk Text Input"
   ↓ showImportTransactionsFromTextInput()
   
3. "Record Transfer"
   ↓ showImportTransfer()
   
4. "Investment"
   ↓ showImportInvestment()
```

### Import Formats Defined

**Location:** [lib/helpers/shared_strings_helper.dart](lib/helpers/shared_strings_helper.dart)

```dart
static const String fileExtensionQfx = 'qfx'
static const String fileExtensionQif = 'qif'
static const String fileExtensionXlsx = 'xlsx'
static const String fileExtensionCsv = 'csv'
static const String fileExtensionPdf = 'pdf'

static const String fileTypeQfx = 'QFX'
static const String fileTypeQif = 'QIF'
// ... etc
```

### Special Imports

#### Transfer Import

**Location:** [lib/views/imports/transfer/transfer_import_view.dart](lib/views/imports/transfer/transfer_import_view.dart)

- Manual inter-account transfer recording

#### Investment Import

**Location:** [lib/views/imports/investment/investment_import_view.dart](lib/views/imports/investment/investment_import_view.dart)

- Investment-specific transaction fields
- Uses `InvestmentImportFields` helper
- Supports stock actions: BUY, SELL, DIVIDEND, etc.

#### Free-Form Text Import

**Location:** [lib/views/imports/shared/transactions_text_import_view.dart](lib/views/imports/shared/transactions_text_import_view.dart)

- Allows pasting transaction data as plain text
- Flexible parsing of date, amount, and description

---

## 7. Architecture Patterns Used

### Pattern: **Format-Specific Loader Pattern**

Each format implements:

1. **Format-specific file reading** (sync or async)
2. **Format-specific parsing** → produces `ImportEntry[]`
3. **Returns standardized `ImportData` wrapper**

### Pattern: **User Configuration Dialog**

CSV and XLSX both use column mapper dialogs:

- User reviews preview rows
- Maps source columns to transaction fields
- Produces `Map<String, String>` configuration
- Passed to loader to apply mappings

### Pattern: **Fallback & Diagnostics**

- All loaders track skip reasons in `ImportDiagnostics`
- Display summary: "parsed X entries and skipped Y rows"
- Each skipped row reason is counted separately

### Pattern: **Account Auto-Detection**

- QFX can extract account ID from file
- System looks up matching account: `findByIdAndType(accountId, accountType)`
- CSV/QIF/XLSX require manual account selection

---

## 8. Test Coverage

**Location:** [test/unit/](test/unit/)

- `import_csv_test.dart` - CSV parsing tests
- `import_qif_test.dart` - QIF parsing tests
- `import_qfx_test.dart` - QFX parsing tests
- `csv_test.dart` - CSV utility tests
- `value_parser_test.dart` - Amount/value parsing tests

**Location:** [test/widgets/](test/widgets/)

- `import_csv_ux_test.dart` - CSV UI tests
- `import_wizard_test.dart` - Wizard UI tests

---

## 9. Dependencies

**Key Packages:**

- `csv` - CSV parsing (RFC-compliant)
- `archive` - ZIP extraction for XLSX
- `path` - File path utilities
- `intl` - Date formatting for QIF (`DateFormat`)
- `file_picker` - File selection dialog

---

## 10. Adding New Import Formats

To add a new import format (e.g., ODS, PSAFEX):

### 1. Create loader file

```dart
// lib/views/imports/formats/ods_import_view.dart
Future<void> importODS(BuildContext context, String filePath) async { }
ImportData loadODS(List<String> headers, List<List<String>> dataRows, Map<String, String> columnMapping) { }
```

### 2. Register in dispatcher

```dart
// lib/views/imports/import_wizard_view.dart
case SharedStrings.fileExtensionOds:
  importODS(context, filePath);
```

### 3. Add file extension constant

```dart
// lib/helpers/shared_strings_helper.dart
static const String fileExtensionOds = 'ods'
static const String fileTypeOds = 'ODS'
```

### 4. Update wizard

```dart
// lib/views/imports/import_wizard_view.dart
_supportedTransactionImportFileExtensions = [..., 'ods']
```

### 5. Add tests

```dart
// test/unit/import_ods_test.dart
test/widgets/import_ods_ux_test.dart
```

---

## 11. Key File Locations Summary

| Component                  | Location                                                                |
| -------------------------- | ----------------------------------------------------------------------- |
| **Core Data Models**       | `lib/shared/domain/{transaction,account}_entity.dart`                   |
| **Import Data Structures** | `lib/views/imports/shared/data_import_view.dart`                        |
| **Format Dispatcher**      | `lib/views/imports/import_wizard_view.dart`                             |
| **CSV Loader**             | `lib/views/imports/formats/csv_import_view.dart`                        |
| **QIF Loader**             | `lib/views/imports/formats/qif_import_view.dart`                        |
| **QFX Loader**             | `lib/views/imports/formats/qfx_import_view.dart`                        |
| **XLSX Loader**            | `lib/views/imports/formats/xlsx_import_view.dart`                       |
| **PDF Loader**             | `lib/views/imports/shared/ai_pdf_import_service.dart`                   |
| **Column Mapper UI**       | `lib/widgets/dialogs/csv_column_mapper_dialog.dart`                     |
| **Import Preview UI**      | `lib/views/imports/shared/transactions_import_list_preview_widget.dart` |
| **Constants**              | `lib/helpers/shared_strings_helper.dart`                                |
| **Tests**                  | `test/unit/import_*.dart`, `test/widgets/import_*_test.dart`            |
