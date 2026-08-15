// ignore: fcheck_one_class_per_file
// ignore: fcheck_hardcoded_strings
// ignore: fcheck_magic_numbers
import 'package:path/path.dart' as path;
import 'package:pdfrx/pdfrx.dart';

const int _minimumKeywordMatches = 2;
const int _minimumTransactionsForStatement = 2;

/// Represents a single normalized transaction extracted from a PDF statement.
class BankStatementTransactionRecord {
  /// Creates a normalized transaction record.
  const BankStatementTransactionRecord({
    required this.date,
    required this.description,
    required this.amount,
  });

  /// Posting date of the transaction.
  final DateTime date;

  /// Transaction description/payee text.
  final String description;

  /// Signed amount string, preserving the original locale formatting from the source document.
  final String amount;
}

/// Represents parsed statement details extracted from a PDF document.
class BankStatementParseResult {
  /// Creates a parsed statement result.
  const BankStatementParseResult({
    required this.filePath,
    required this.fileName,
    required this.rawText,
    required this.transactions,
    required this.accountHints,
    required this.isBankStatement,
    this.statementBalance,
    this.detectedCurrencyCode,
  });

  /// Absolute path of the source PDF file.
  final String filePath;

  /// File name of the source PDF file.
  final String fileName;

  /// Full text extracted from the PDF document.
  final String rawText;

  /// Parsed transaction entries found in the PDF text.
  final List<BankStatementTransactionRecord> transactions;

  /// Account identifiers or account suffix hints detected in statement text.
  final List<String> accountHints;

  /// True when the document strongly matches a bank statement pattern.
  final bool isBankStatement;

  /// Ending/closing balance detected from statement text.
  final double? statementBalance;

  /// Detected ISO-4217 currency code for statement amounts, when available.
  final String? detectedCurrencyCode;
}

/// Service that extracts and parses bank statement data from PDF files.
class BankStatementPdfService {
  /// Creates a bank statement PDF parser service.
  const BankStatementPdfService();

  /// Extracts raw text from a PDF file at [filePath].
  Future<String> extractTextFromPdfFile(String filePath) async {
    return _extractTextFromPdf(filePath);
  }

  /// Parses statement content from pre-extracted [rawText].
  BankStatementParseResult parseExtractedText({
    required String rawText,
    required String filePath,
  }) {
    final String normalizedText = rawText.replaceAll('\r', '\n');
    final List<String> lines = normalizedText
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    final int fallbackYear = _resolveFallbackYear(lines);
    final List<BankStatementTransactionRecord> transactions = _extractTransactions(lines, fallbackYear);
    final List<String> accountHints = _extractAccountHints(lines);
    final double? statementBalance = _extractStatementBalance(lines);
    final String? detectedCurrencyCode = _extractDetectedCurrencyCode(normalizedText.toLowerCase());
    final int keywordMatches = _countBankStatementKeywords(normalizedText.toLowerCase());

    final bool hasTransactions = transactions.length >= _minimumTransactionsForStatement;
    final bool hasStatementMetadata =
        keywordMatches >= _minimumKeywordMatches || accountHints.isNotEmpty || statementBalance != null;

    return BankStatementParseResult(
      filePath: filePath,
      fileName: path.basename(filePath),
      rawText: normalizedText,
      transactions: transactions,
      accountHints: accountHints,
      isBankStatement: hasTransactions && hasStatementMetadata,
      statementBalance: statementBalance,
      detectedCurrencyCode: detectedCurrencyCode,
    );
  }

  /// Extracts a likely ISO-4217 currency code from [lowercaseText].
  String? _extractDetectedCurrencyCode(String lowercaseText) {
    if (lowercaseText.contains('€') ||
        lowercaseText.contains(' eur ') ||
        lowercaseText.contains(' euro ') ||
        lowercaseText.contains(' euros ')) {
      return 'EUR';
    }

    if (lowercaseText.contains('\$') ||
        lowercaseText.contains(' usd ') ||
        lowercaseText.contains(' us dollar ') ||
        lowercaseText.contains(' dollars ')) {
      return 'USD';
    }

    if (lowercaseText.contains('£') || lowercaseText.contains(' gbp ') || lowercaseText.contains(' pound ')) {
      return 'GBP';
    }

    return null;
  }

  /// Extracts plain text from all pages of the PDF at [filePath] using pdfrx.
  Future<String> _extractTextFromPdf(String filePath) async {
    await pdfrxFlutterInitialize();
    final PdfDocument document = await PdfDocument.openFile(filePath);
    try {
      if (document.pages.isEmpty) {
        return '';
      }

      final StringBuffer buffer = StringBuffer();
      for (final PdfPage page in document.pages) {
        final PdfPageText pageText = await page.loadStructuredText();
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(pageText.fullText);
      }
      return buffer.toString();
    } finally {
      document.dispose();
    }
  }

  /// Counts how many bank statement keywords appear in [lowercaseText].
  int _countBankStatementKeywords(String lowercaseText) {
    const List<String> keywords = <String>[
      'bank statement',
      'statement period',
      'account number',
      'beginning balance',
      'opening balance',
      'ending balance',
      'closing balance',
      'available balance',
      'transaction date',
      'withdrawal',
      'deposit',
    ];

    int matches = 0;
    for (final String keyword in keywords) {
      if (lowercaseText.contains(keyword)) {
        matches = matches + 1;
      }
    }
    return matches;
  }

  /// Extracts candidate account identifier hints from [lines].
  List<String> _extractAccountHints(List<String> lines) {
    final Set<String> hints = <String>{};

    final RegExp accountPattern = RegExp(
      r'(?:account|acct)(?:\s*(?:number|no\.?|#))?\s*[:\-]?\s*([A-Za-z0-9\-*]{4,})',
      caseSensitive: false,
    );
    final RegExp endingPattern = RegExp(
      r'ending\s+in\s+([0-9]{4,})',
      caseSensitive: false,
    );

    for (final String line in lines) {
      for (final RegExpMatch match in accountPattern.allMatches(line)) {
        final String token = _normalizeToken(match.group(1) ?? '');
        if (token.length >= 4) {
          hints.add(token);
          final String digits = _digitsOnly(token);
          if (digits.length >= 4) {
            hints.add(digits.substring(digits.length - 4));
          }
        }
      }

      for (final RegExpMatch match in endingPattern.allMatches(line)) {
        final String digits = _digitsOnly(match.group(1) ?? '');
        if (digits.length >= 4) {
          hints.add(digits);
          hints.add(digits.substring(digits.length - 4));
        }
      }
    }

    return hints.toList();
  }

  /// Extracts a likely ending/closing balance from [lines].
  double? _extractStatementBalance(List<String> lines) {
    final RegExp amountPattern = RegExp(
      r'([+\-]?\(?\$?\s*\d[\d,.\s]*\)?(?:\s*(?:CR|DR))?)',
      caseSensitive: false,
    );

    double? detectedBalance;
    for (final String line in lines) {
      final String lower = line.toLowerCase();
      if (!_isBalanceLine(lower)) {
        continue;
      }

      for (final RegExpMatch match in amountPattern.allMatches(line)) {
        final String token = match.group(1) ?? '';
        final double? amount = _parseAmountToken(token);
        if (amount != null) {
          detectedBalance = amount;
        }
      }
    }

    return detectedBalance;
  }

  /// Returns true when [lowercaseLine] likely describes a balance field.
  bool _isBalanceLine(String lowercaseLine) {
    return lowercaseLine.contains('ending balance') ||
        lowercaseLine.contains('closing balance') ||
        lowercaseLine.contains('available balance') ||
        lowercaseLine.contains('current balance') ||
        lowercaseLine.contains('new balance');
  }

  /// Extracts transaction rows from [lines], applying [fallbackYear] when needed.
  List<BankStatementTransactionRecord> _extractTransactions(
    List<String> lines,
    int fallbackYear,
  ) {
    final RegExp transactionPattern = RegExp(
      r'^(\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?)\s+(.+?)\s+([+\-]?\(?\$?\s*\d[\d,.\s]*\)?(?:\s*(?:CR|DR))?)$',
      caseSensitive: false,
    );

    final Set<String> dedupeKeys = <String>{};
    final List<BankStatementTransactionRecord> records = <BankStatementTransactionRecord>[];

    for (final String line in lines) {
      final String normalizedLine = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      final RegExpMatch? match = transactionPattern.firstMatch(normalizedLine);
      if (match == null) {
        continue;
      }

      final String dateToken = match.group(1) ?? '';
      final String description = (match.group(2) ?? '').trim();
      final String amountToken = (match.group(3) ?? '').trim();

      if (_isSummaryDescription(description)) {
        continue;
      }

      final DateTime? date = _parseDateToken(dateToken, fallbackYear);
      final double? amount = _parseAmountToken(amountToken);

      if (date == null || amount == null || description.isEmpty) {
        continue;
      }

      final String dedupeKey = '${date.toIso8601String()}|${description.toLowerCase()}|$amountToken';
      if (dedupeKeys.contains(dedupeKey)) {
        continue;
      }

      dedupeKeys.add(dedupeKey);
      records.add(
        BankStatementTransactionRecord(
          date: date,
          description: description,
          amount: amountToken,
        ),
      );
    }

    final List<BankStatementTransactionRecord> multilineRecords = _extractTransactionsFromSplitRows(
      lines: lines,
      fallbackYear: fallbackYear,
      dedupeKeys: dedupeKeys,
    );
    records.addAll(multilineRecords);

    return records;
  }

  /// Extracts transactions from statements that split rows into two lines: posting date/ref then value-date/details.
  List<BankStatementTransactionRecord> _extractTransactionsFromSplitRows({
    required List<String> lines,
    required int fallbackYear,
    required Set<String> dedupeKeys,
  }) {
    final RegExp postingDateRefPattern = RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\s+\d+\s*$');
    final RegExp leadingDatePattern = RegExp(r'^(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\s+');
    final RegExp amountPattern = RegExp(r'[+\-]?\$?(?:\d{1,3}(?:[.,]\d{3})+|\d+)(?:[.,]\d{2,3})');

    final List<BankStatementTransactionRecord> records = <BankStatementTransactionRecord>[];

    for (int lineIndex = 0; lineIndex < lines.length - 1; lineIndex = lineIndex + 1) {
      final String postingLine = lines[lineIndex].replaceAll(RegExp(r'\s+'), ' ').trim();
      final String detailsLine = lines[lineIndex + 1].replaceAll(RegExp(r'\s+'), ' ').trim();

      if (!postingDateRefPattern.hasMatch(postingLine)) {
        continue;
      }

      final RegExpMatch? dateMatch = leadingDatePattern.firstMatch(detailsLine);
      if (dateMatch == null) {
        continue;
      }

      final String dateToken = dateMatch.group(1) ?? '';
      final DateTime? date = _parseDateToken(dateToken, fallbackYear);
      if (date == null) {
        continue;
      }

      final List<RegExpMatch> amountMatches = amountPattern.allMatches(detailsLine).toList();
      if (amountMatches.length < 2) {
        continue;
      }

      // Last amount is usually running balance; second to last is transaction amount.
      final RegExpMatch transactionAmountMatch = amountMatches[amountMatches.length - 2];
      final String amountToken = transactionAmountMatch.group(0) ?? '';
      if (_parseAmountToken(amountToken) == null) {
        continue;
      }

      final int descriptionStart = dateMatch.end;
      final int descriptionEnd = transactionAmountMatch.start;
      if (descriptionEnd <= descriptionStart) {
        continue;
      }

      final String description = detailsLine.substring(descriptionStart, descriptionEnd).trim();
      if (description.isEmpty || _isSummaryDescription(description)) {
        continue;
      }

      final String dedupeKey = '${date.toIso8601String()}|${description.toLowerCase()}|$amountToken';
      if (dedupeKeys.contains(dedupeKey)) {
        continue;
      }

      dedupeKeys.add(dedupeKey);
      records.add(
        BankStatementTransactionRecord(
          date: date,
          description: description,
          amount: amountToken,
        ),
      );
    }

    return records;
  }

  /// Returns true when [description] appears to be a statement summary row.
  bool _isSummaryDescription(String description) {
    final String lowered = description.toLowerCase();
    return lowered.contains('opening balance') ||
        lowered.contains('beginning balance') ||
        lowered.contains('ending balance') ||
        lowered.contains('closing balance') ||
        lowered.contains('available balance') ||
        lowered.contains('balance forward') ||
        lowered == 'total' ||
        lowered == 'subtotal';
  }

  /// Resolves the most likely statement year from explicit dates present in [lines].
  int _resolveFallbackYear(List<String> lines) {
    final RegExp dateWithYearPattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');

    DateTime? latestDate;
    for (final String line in lines) {
      for (final RegExpMatch match in dateWithYearPattern.allMatches(line)) {
        final DateTime? parsed = _parseDateToken(match.group(0) ?? '', DateTime.now().year);
        if (parsed == null) {
          continue;
        }
        if (latestDate == null || parsed.isAfter(latestDate)) {
          latestDate = parsed;
        }
      }
    }

    return latestDate?.year ?? DateTime.now().year;
  }

  /// Parses [token] into a concrete date, using [fallbackYear] when year is missing.
  DateTime? _parseDateToken(String token, int fallbackYear) {
    final List<String> parts = token.replaceAll('-', '/').split('/');
    if (parts.length < 2 || parts.length > 3) {
      return null;
    }

    final int? first = int.tryParse(parts[0]);
    final int? second = int.tryParse(parts[1]);
    if (first == null || second == null) {
      return null;
    }

    int year = fallbackYear;
    if (parts.length == 3) {
      final int? parsedYear = int.tryParse(parts[2]);
      if (parsedYear == null) {
        return null;
      }
      year = parsedYear < 100 ? (parsedYear >= 70 ? 1900 + parsedYear : 2000 + parsedYear) : parsedYear;
    }

    int month = first;
    int day = second;

    if (first > 12 && second <= 12) {
      day = first;
      month = second;
    } else if (second > 12 && first <= 12) {
      day = second;
      month = first;
    }

    if (!_isValidMonthDay(month, day)) {
      return null;
    }

    final DateTime candidate = DateTime(year, month, day);
    if (candidate.year != year || candidate.month != month || candidate.day != day) {
      return null;
    }

    return candidate;
  }

  /// Returns true when [month] and [day] represent a valid calendar day.
  bool _isValidMonthDay(int month, int day) {
    if (month < 1 || month > 12) {
      return false;
    }
    if (day < 1 || day > 31) {
      return false;
    }
    return true;
  }

  /// Parses [rawAmountToken] into a signed decimal amount.
  double? _parseAmountToken(String rawAmountToken) {
    String token = rawAmountToken.trim().toUpperCase();
    if (token.isEmpty) {
      return null;
    }

    final bool isDebit = token.contains('DR');
    final bool isCredit = token.contains('CR');
    final bool hasParentheses = token.contains('(') && token.contains(')');
    final bool hasLeadingMinus = token.startsWith('-');
    final bool hasTrailingMinus = token.endsWith('-');

    token = token.replaceAll('CR', '').replaceAll('DR', '').replaceAll(RegExp(r'[^0-9,.-]'), '');

    token = token.replaceAll('-', '');
    if (token.isEmpty) {
      return null;
    }

    final String normalized = _normalizeNumberSeparators(token);
    final double? parsed = double.tryParse(normalized);
    if (parsed == null) {
      return null;
    }

    double amount = parsed;
    if (hasParentheses || hasLeadingMinus || hasTrailingMinus || isDebit) {
      amount = -amount.abs();
    } else if (isCredit) {
      amount = amount.abs();
    }

    return amount;
  }

  /// Normalizes decimal/thousands separators in [token] to standard dot notation.
  String _normalizeNumberSeparators(String token) {
    String normalized = token;
    final int commaIndex = normalized.lastIndexOf(',');
    final int dotIndex = normalized.lastIndexOf('.');

    if (commaIndex != -1 && dotIndex != -1) {
      if (commaIndex > dotIndex) {
        normalized = normalized.replaceAll('.', '');
        normalized = normalized.replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
      return normalized;
    }

    if (commaIndex != -1) {
      final bool commaAsDecimal = RegExp(r',\d{1,2}$').hasMatch(normalized);
      if (commaAsDecimal) {
        normalized = normalized.replaceAll('.', '');
        normalized = normalized.replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
      return normalized;
    }

    final int dotCount = '.'.allMatches(normalized).length;
    if (dotCount > 1) {
      final int lastDotIndex = normalized.lastIndexOf('.');
      final String beforeLastDot = normalized.substring(0, lastDotIndex).replaceAll('.', '');
      final String afterLastDot = normalized.substring(lastDotIndex + 1);
      normalized = '$beforeLastDot.$afterLastDot';
    }

    return normalized;
  }

  /// Normalizes [token] to uppercase alphanumeric characters plus `*`.
  String _normalizeToken(String token) {
    return token.replaceAll(RegExp(r'[^A-Za-z0-9*]'), '').toUpperCase();
  }

  /// Extracts only digit characters from [token].
  String _digitsOnly(String token) {
    return token.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
