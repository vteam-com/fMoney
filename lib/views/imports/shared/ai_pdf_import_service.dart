// ignore: fcheck_duplicate_code
// ignore: fcheck_hardcoded_strings
// ignore: fcheck_magic_numbers
import 'dart:convert';

import 'package:money/helpers/app_logger_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/ollama_service.dart';
import 'package:money/views/home/ai/bank_statement_pdf_service.dart';
import 'package:path/path.dart' as path;

const int _maxPdfTextCharsForOllamaImport = 45000;
const int _minimumAccountHintLength = 3;

/// Service that extracts and normalizes bank statement transactions from a PDF using Ollama when available.
class AiPdfImportService {
  /// Creates a PDF import service with an optional [bankStatementPdfService] override for testing.
  const AiPdfImportService({
    BankStatementPdfService bankStatementPdfService = const BankStatementPdfService(),
  }) : _bankStatementPdfService = bankStatementPdfService;

  final BankStatementPdfService _bankStatementPdfService;

  /// Parses [filePath] into a normalized bank statement result, using AI first and heuristic parsing as fallback.
  Future<BankStatementParseResult> parsePdfStatement({
    required final String filePath,
  }) async {
    final String extractedText = await _bankStatementPdfService.extractTextFromPdfFile(filePath);
    final BankStatementParseResult fallbackStatement = _bankStatementPdfService.parseExtractedText(
      rawText: extractedText,
      filePath: filePath,
    );
    final bool ollamaReady = await _ensureOllamaReady();
    final List<String> aiAccountHints = await _extractAccountHintsWithOllama(
      pdfText: extractedText,
      ollamaReady: ollamaReady,
    );

    final BankStatementParseResult? aiStatement = await _reviewStatementWithOllama(
      filePath: filePath,
      pdfText: extractedText,
      ollamaReady: ollamaReady,
    );
    if (aiStatement != null) {
      return _copyStatementWithMergedAccountHints(
        statement: aiStatement,
        extraAccountHints: aiAccountHints,
        preferredDetectedCurrencyCode: fallbackStatement.detectedCurrencyCode,
      );
    }

    return _copyStatementWithMergedAccountHints(
      statement: fallbackStatement,
      extraAccountHints: aiAccountHints,
    );
  }

  /// Returns true when Ollama is installed, running, and has a selected model.
  Future<bool> _ensureOllamaReady() async {
    await OllamaService.getLastUserSelectedModel();
    final OllamaStatus status = await OllamaService.checkOllamaStatus();
    if (!status.isInstalled || !status.isRunning) {
      return false;
    }

    if (OllamaService.selectedModel.isEmpty) {
      await OllamaService.loadAvailableModels();
    }

    return OllamaService.selectedModel.isNotEmpty;
  }

  /// Sends the extracted PDF text to Ollama and parses transaction rows from the structured response.
  Future<BankStatementParseResult?> _reviewStatementWithOllama({
    required final String filePath,
    required final String pdfText,
    required final bool ollamaReady,
  }) async {
    if (!ollamaReady) {
      return null;
    }

    final String prompt = _buildPdfReviewPrompt(pdfText);

    AppLogger.debug(
      module: 'ai_pdf_import_service',
      operation: '_reviewStatementWithOllama',
      message: 'AI PROMPT INPUT:\n$prompt',
    );

    final Map<String, dynamic> payload = <String, dynamic>{
      'model': OllamaService.selectedModel,
      'messages': <Map<String, String>>[
        <String, String>{
          'role': SharedStrings.payloadRoleUser,
          'content': prompt,
        },
      ],
      'stream': false,
    };

    final Map<String, dynamic> response = await OllamaService.sendPayload(payload);
    final dynamic rawResponse = response[SharedStrings.payloadKeyResponse];

    AppLogger.debug(
      module: 'ai_pdf_import_service',
      operation: '_reviewStatementWithOllama',
      message: 'AI RESPONSE OUTPUT:\n$rawResponse',
    );

    if (rawResponse is! String || rawResponse.trim().isEmpty) {
      return null;
    }

    final String jsonPayload = _extractJsonPayloadFromResponse(rawResponse);
    if (jsonPayload.isEmpty) {
      return null;
    }

    final dynamic decoded = json.decode(jsonPayload);
    final List<BankStatementTransactionRecord> transactions = _extractTransactionsFromDecoded(decoded);
    if (transactions.isEmpty) {
      return null;
    }
    final String? detectedCurrencyCode = _extractDetectedCurrencyCodeFromDecoded(decoded);

    return _buildStatementFromOllamaTransactions(
      filePath: filePath,
      pdfText: pdfText,
      transactions: transactions,
      detectedCurrencyCode: detectedCurrencyCode,
    );
  }

  /// Extracts account hints from PDF text using Ollama.
  Future<List<String>> _extractAccountHintsWithOllama({
    required final String pdfText,
    required final bool ollamaReady,
  }) async {
    if (!ollamaReady) {
      return <String>[];
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'model': OllamaService.selectedModel,
      'messages': <Map<String, String>>[
        <String, String>{
          'role': SharedStrings.payloadRoleUser,
          'content': _buildAccountHintsPrompt(pdfText),
        },
      ],
      'stream': false,
    };

    final Map<String, dynamic> response = await OllamaService.sendPayload(payload);
    final dynamic rawResponse = response[SharedStrings.payloadKeyResponse];
    if (rawResponse is! String || rawResponse.trim().isEmpty) {
      return <String>[];
    }

    final String jsonPayload = _extractJsonPayloadFromResponse(rawResponse);
    if (jsonPayload.isEmpty) {
      return <String>[];
    }

    final dynamic decoded = json.decode(jsonPayload);
    return _normalizeAccountHintsFromDecoded(decoded);
  }

  /// Builds the prompt instructing Ollama to return only transaction rows as JSON array.
  String _buildPdfReviewPrompt(final String pdfText) {
    final String preprocessed = _preprocessPdfText(pdfText);
    final String normalizedText = preprocessed.length > _maxPdfTextCharsForOllamaImport
        ? preprocessed.substring(0, _maxPdfTextCharsForOllamaImport)
        : preprocessed;

    return '''
You are a financial transaction extraction engine.

Your task:
Extract all bank transactions from the text exactly as provided, regardless of format, currency, or layout.

Output:
A JSON array of objects with the following fields:
- date: string (EXACTLY as printed in the statement, do NOT convert or reformat)
- description: string
- amount: string (EXACTLY as printed in the statement, do NOT convert or reformat, but apply correct sign)

Rules:
1. Identify rows that contain a date + description + amount.
2. Copy the date EXACTLY as it appears. Do NOT convert to any other format.
3. Copy the amount EXACTLY as it appears. Do NOT convert number formats. Keep "1.234,56" as "1.234,56".
4. CRITICAL - Determine the correct sign of each amount:
   - Many statements use separate columns for money going out vs money coming in.
   - Column headers that mean MONEY OUT (make amount NEGATIVE with "-" prefix):
     "Debit", "Débit", "Payment", "Paiement", "Withdrawal", "Retrait", "Charge", "Expense", "Sortie", "Débiteur"
   - Column headers that mean MONEY IN (make amount POSITIVE with "+" prefix):
     "Credit", "Crédit", "Deposit", "Dépôt", "Receipt", "Recette", "Entrée", "Créditeur"
   - If a single "Amount" column contains both positive and negative values, keep the sign as-is.
   - If unsure which column an amount belongs to, look at the column position relative to the headers.
5. Ignore:
   - Balances (opening, closing, running)
   - Subtotals or totals
   - Category summaries
   - Graphs
   - Headers/footers
   - Page numbers
6. Do NOT invent transactions.
7. Do NOT summarize.
8. Output ONLY the JSON array. No explanations.

Example output:
[
  {
    "date": "02-10-24",
    "description": "DEBIT / ENDESA ENERGIA",
    "amount": "-15,95"
  },
  {
    "date": "05-10-24",
    "description": "SALARY DEPOSIT",
    "amount": "+2.500,00"
  }
]

PDF_TEXT_START
$normalizedText
PDF_TEXT_END
''';
  }

  /// Builds the prompt instructing Ollama to extract account identifiers for matching local accounts.
  String _buildAccountHintsPrompt(final String pdfText) {
    final String normalizedText = pdfText.length > _maxPdfTextCharsForOllamaImport
        ? pdfText.substring(0, _maxPdfTextCharsForOllamaImport)
        : pdfText;

    return '''
You are a financial document parser.

Task:
Extract account identifiers from the PDF text that can match local accounts.

Output:
Return ONLY a JSON array of strings.

Include when available:
- Full account number
- Masked account number
- Last 4 digits
- IBAN fragments
- Account name labels

Rules:
- Do not include transaction descriptions as account hints.
- Do not include balances.
- Remove duplicates.
- Do not add explanations.

PDF_TEXT_START
$normalizedText
PDF_TEXT_END
''';
  }

  /// Extracts the first JSON payload (array preferred, object fallback) found inside [responseText].
  String _extractJsonPayloadFromResponse(final String responseText) {
    String sanitized = responseText.trim();
    sanitized = sanitized.replaceAll(RegExp(r'```json', caseSensitive: false), '').replaceAll('```', '').trim();

    final int firstBracket = sanitized.indexOf('[');
    final int lastBracket = sanitized.lastIndexOf(']');
    final bool hasArray = firstBracket != -1 && lastBracket != -1 && lastBracket > firstBracket;

    final int firstBrace = sanitized.indexOf('{');
    final int lastBrace = sanitized.lastIndexOf('}');
    final bool hasObject = firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace;

    if (hasArray && (!hasObject || firstBracket < firstBrace)) {
      return sanitized.substring(firstBracket, lastBracket + 1);
    }

    if (hasObject) {
      return sanitized.substring(firstBrace, lastBrace + 1);
    }

    return '';
  }

  /// Normalizes account hints from decoded JSON payload [decoded].
  List<String> _normalizeAccountHintsFromDecoded(final dynamic decoded) {
    if (decoded is List<dynamic>) {
      return _normalizeAccountHints(decoded);
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic accountHints = decoded['accountHints'];
      if (accountHints is List<dynamic>) {
        return _normalizeAccountHints(accountHints);
      }
    }

    return <String>[];
  }

  /// Returns deduplicated account hints from [rawHints].
  List<String> _normalizeAccountHints(final List<dynamic> rawHints) {
    final Set<String> uniqueHints = <String>{};
    for (final dynamic rawHint in rawHints) {
      final String hint = rawHint.toString().trim();
      if (hint.length >= _minimumAccountHintLength) {
        uniqueHints.add(hint);
      }
    }
    return uniqueHints.toList();
  }

  /// Extracts transaction rows from decoded Ollama JSON [decoded].
  List<BankStatementTransactionRecord> _extractTransactionsFromDecoded(final dynamic decoded) {
    if (decoded is List<dynamic>) {
      return _parseTransactionsFromOllama(decoded);
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic transactions = decoded['transactions'];
      if (transactions is List<dynamic>) {
        return _parseTransactionsFromOllama(transactions);
      }

      if (decoded.containsKey('date') || decoded.containsKey('description') || decoded.containsKey('amount')) {
        return _parseTransactionsFromOllama(<dynamic>[decoded]);
      }
    }

    return <BankStatementTransactionRecord>[];
  }

  /// Extracts a likely ISO-4217 currency code from decoded Ollama payload [decoded].
  String? _extractDetectedCurrencyCodeFromDecoded(final dynamic decoded) {
    if (decoded is List<dynamic>) {
      return _extractMostFrequentCurrencyCode(decoded);
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic transactions = decoded['transactions'];
      if (transactions is List<dynamic>) {
        return _extractMostFrequentCurrencyCode(transactions);
      }

      return _normalizeCurrencyCodeFromDynamic(decoded['currency']);
    }

    return null;
  }

  /// Returns the most frequent normalized currency code from [rawTransactions].
  String? _extractMostFrequentCurrencyCode(final List<dynamic> rawTransactions) {
    final Map<String, int> frequency = <String, int>{};

    for (final dynamic item in rawTransactions) {
      if (item is! Map<dynamic, dynamic>) {
        continue;
      }

      final String? currencyCode = _normalizeCurrencyCodeFromDynamic(item['currency']);
      if (currencyCode == null) {
        continue;
      }

      final int currentCount = frequency[currencyCode] ?? 0;
      frequency[currencyCode] = currentCount + 1;
    }

    if (frequency.isEmpty) {
      return null;
    }

    String? winnerCode;
    int winnerCount = 0;
    for (final MapEntry<String, int> entry in frequency.entries) {
      if (entry.value > winnerCount) {
        winnerCode = entry.key;
        winnerCount = entry.value;
      }
    }

    return winnerCode;
  }

  /// Normalizes a currency token from [value] into uppercase 3-letter ISO code.
  String? _normalizeCurrencyCodeFromDynamic(final dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim().toUpperCase();
    if (text.length != 3 || !RegExp(r'^[A-Z]{3}$').hasMatch(text)) {
      return null;
    }

    return text;
  }

  /// Returns a copy of [statement] with merged account hints.
  BankStatementParseResult _copyStatementWithMergedAccountHints({
    required final BankStatementParseResult statement,
    required final List<String> extraAccountHints,
    final String? preferredDetectedCurrencyCode,
  }) {
    if (extraAccountHints.isEmpty && (preferredDetectedCurrencyCode == null || preferredDetectedCurrencyCode.isEmpty)) {
      return statement;
    }

    final Set<String> mergedHints = <String>{
      ...statement.accountHints,
      ...extraAccountHints,
    };
    final String? resolvedDetectedCurrencyCode =
        (preferredDetectedCurrencyCode != null && preferredDetectedCurrencyCode.isNotEmpty)
        ? preferredDetectedCurrencyCode
        : statement.detectedCurrencyCode;

    return BankStatementParseResult(
      filePath: statement.filePath,
      fileName: statement.fileName,
      rawText: statement.rawText,
      transactions: statement.transactions,
      accountHints: mergedHints.toList(),
      isBankStatement: statement.isBankStatement,
      statementBalance: statement.statementBalance,
      detectedCurrencyCode: resolvedDetectedCurrencyCode,
    );
  }

  /// Splits packed PDF text into structured rows with tab-separated fields.
  ///
  /// Many PDF extractors concatenate all text without delimiters. This method
  /// detects transaction rows by their date prefix pattern and inserts
  /// newlines so the AI can identify individual rows. Field separation
  /// (description vs amount) is left to the AI, which handles digits in
  /// descriptions far better than a regex can.
  String _preprocessPdfText(final String text) {
    String result = text;

    // Insert newlines before section keywords to separate header/footer from data.
    result = result.replaceAllMapped(
      RegExp(
        r'(?=(?:PREVIOUS BALANCE|FINAL BALANCE|DEPOSITS AT SIGHT|Account movements|BROKEN DOWN REPORT))',
        caseSensitive: false,
      ),
      (final Match _) => '\n',
    );

    // Insert newline before each date pattern that likely starts a transaction row.
    result = result.replaceAllMapped(
      RegExp(r'(?=\d{2}[-/]\d{2}[-/](?:\d{4}|\d{2}))'),
      (final Match _) => '\n',
    );

    // Collapse multiple blank lines into one.
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }

  /// Creates a [BankStatementParseResult] from normalized [transactions] returned by Ollama.
  BankStatementParseResult _buildStatementFromOllamaTransactions({
    required final String filePath,
    required final String pdfText,
    required final List<BankStatementTransactionRecord> transactions,
    required final String? detectedCurrencyCode,
  }) {
    return BankStatementParseResult(
      filePath: filePath,
      fileName: path.basename(filePath),
      rawText: pdfText,
      transactions: transactions,
      accountHints: <String>[],
      isBankStatement: transactions.isNotEmpty,
      statementBalance: null,
      detectedCurrencyCode: detectedCurrencyCode,
    );
  }

  /// Parses normalized transaction objects from Ollama response data.
  List<BankStatementTransactionRecord> _parseTransactionsFromOllama(final dynamic rawTransactions) {
    if (rawTransactions is! List<dynamic>) {
      return <BankStatementTransactionRecord>[];
    }

    final List<BankStatementTransactionRecord> transactions = <BankStatementTransactionRecord>[];
    for (final dynamic item in rawTransactions) {
      if (item is! Map<dynamic, dynamic>) {
        continue;
      }

      final DateTime? date = _parseDateFromDynamic(item['date']);
      final String description = (item['description'] ?? '').toString().trim();
      final String amountText = (item['amount'] ?? '').toString().trim();
      if (date == null || description.isEmpty || amountText.isEmpty) {
        continue;
      }

      transactions.add(
        BankStatementTransactionRecord(
          date: date,
          description: description,
          amount: amountText,
        ),
      );
    }

    return transactions;
  }

  /// Parses a date from [value], supporting DD-MM-YY, DD-MM-YYYY, DD/MM/YY, DD/MM/YYYY, and YYYY-MM-DD formats.
  DateTime? _parseDateFromDynamic(final dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    // Try ISO format first (YYYY-MM-DD).
    final DateTime? iso = DateTime.tryParse(text);
    if (iso != null) {
      return iso;
    }

    // Try European formats: DD-MM-YY, DD-MM-YYYY, DD/MM/YY, DD/MM/YYYY.
    final RegExp europeanDate = RegExp(r'^(\d{2})[-/](\d{2})[-/](\d{2,4})$');
    final RegExpMatch? match = europeanDate.firstMatch(text);
    if (match != null) {
      final int? day = int.tryParse(match.group(1)!);
      final int? month = int.tryParse(match.group(2)!);
      int? year = int.tryParse(match.group(3)!);
      if (day == null || month == null || year == null) {
        return null;
      }
      if (year < 100) {
        year += 2000;
      }
      if (month < 1 || month > 12 || day < 1 || day > 31) {
        return null;
      }
      return DateTime(year, month, day);
    }

    return null;
  }
}
