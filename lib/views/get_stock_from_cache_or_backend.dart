import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:money/data/models/stock_data_price.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/providers/security.dart';
import 'package:money/views/data.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/pure/snack_bar.dart';

const String flagAsInvalidSymbol = 'invalid-symbol';
const int _csvHeaderRowIndex = 0;
const int _csvColumnCount = 2;
const int _csvDateIndex = 0;
const int _csvPriceIndex = 1;
const int _historyYears = 40;
const int _daysPerYear = 365;
const int _httpOk = 200;
const int _httpUnauthorized = 401;
const int _httpForbidden = 403;
const int _httpNotFound = 404;
const int _httpConflict = 409;

/// Represents stock price history cache.
class StockPriceHistoryCache {
  StockPriceHistoryCache(this.symbol, this.status, [this.lastDateTime]);

  String errorMessage = '';
  List<StockDatePrice> prices = <StockDatePrice>[];
  StockLookupStatus status = StockLookupStatus.notFoundInCache;
  String symbol = '';

  DateTime? lastDateTime;
}

/// Loads stock price history from the local cache and falls back to the backend if needed.
Future<StockPriceHistoryCache> getFromCacheOrBackend(String symbol) async {
  symbol = symbol.toLowerCase();

  StockPriceHistoryCache result = await _loadFromCache(symbol);

  if (result.status != StockLookupStatus.foundInCache) {
    // Try to load from the cloud service
    result = await loadFomBackendAndSaveToCache(symbol);
  }

  return result;
}

/// Loads stock price history from the backend and stores the results in the local cache.
Future<StockPriceHistoryCache> loadFomBackendAndSaveToCache(
  String symbol,
) async {
  final StockPriceHistoryCache result = await _loadFromBackend(symbol);
  if (result.errorMessage.isNotEmpty) {
    SnackBarService.displayError(
      message: result.errorMessage,
      autoDismiss: false,
    );
  }
  switch (result.status) {
    case StockLookupStatus.validSymbol:
      _saveToCache(symbol, result.prices);
      return await _loadFromCache(symbol);
    case StockLookupStatus.invalidSymbol:
      _saveToCacheInvalidSymbol(symbol);
    default:
  }
  return result;
}

enum StockLookupStatus {
  validSymbol,
  invalidSymbol,
  foundInCache,
  notFoundInCache,
  invalidApiKey,
  error,
}

/// Loads stock price history for [symbol] from local preferences cache.
Future<StockPriceHistoryCache> _loadFromCache(final String symbol) async {
  final StockPriceHistoryCache stockPriceHistoryCache = StockPriceHistoryCache(
    symbol,
    StockLookupStatus.foundInCache,
    null,
  );

  String? csvContent;

  try {
    csvContent = PreferenceController.to.getString('stock-$symbol');
    if (csvContent.isEmpty || csvContent == flagAsInvalidSymbol) {
      // give up now
      stockPriceHistoryCache.status = StockLookupStatus.notFoundInCache;
    } else {
      final String dateTimeAsString = PreferenceController.to.getString(
        'stock-date-$symbol',
      );
      if (dateTimeAsString.isNotEmpty) {
        stockPriceHistoryCache.lastDateTime = DateTime.parse(dateTimeAsString);
      }
    }
  } catch (_) {
    //
  }

  if (csvContent != null) {
    final List<String> csvLines = csvContent.split('\n');

    for (int row = _csvHeaderRowIndex; row < csvLines.length; row++) {
      if (row == _csvHeaderRowIndex) {
        // skip header
      } else {
        final List<String> twoColumns = csvLines[row].split(',');
        if (twoColumns.length == _csvColumnCount) {
          final StockDatePrice sp = StockDatePrice(
            date: DateTime.parse(twoColumns[_csvDateIndex]),
            price: double.parse(twoColumns[_csvPriceIndex]),
          );
          stockPriceHistoryCache.prices.add(sp);
        }
      }
    }
    return stockPriceHistoryCache;
  }
  return StockPriceHistoryCache(symbol, StockLookupStatus.notFoundInCache);
}

/// Loads stock price history for [symbol] from the remote API.
Future<StockPriceHistoryCache> _loadFromBackend(String symbol) async {
  final StockPriceHistoryCache result = StockPriceHistoryCache(
    symbol,
    StockLookupStatus.validSymbol,
  );

  if (PreferenceController.to.apiKeyForStocks.isEmpty) {
    // No API Key to make the backend request
    return StockPriceHistoryCache(symbol, StockLookupStatus.invalidApiKey);
  }

  final DateTime numberOfDaysInThePast = DateTime.now().subtract(
    const Duration(days: _daysPerYear * _historyYears),
  );

  final String url =
      'https://api.twelvedata.com/time_series?symbol=$symbol&interval=1day&start_date=${numberOfDaysInThePast.toIso8601String()}&apikey=${PreferenceController.to.apiKeyForStocks}';

  final Uri uri = Uri.parse(url);

  if (symbol == Constants.mockStockSymbol) {
    result.prices = <StockDatePrice>[];
    return result;
  }

  final http.Response response = await http.get(uri);

  if (response.statusCode == _httpOk) {
    try {
      final MyJson data = json.decode(response.body) as MyJson;
      if (data['code'] == _httpUnauthorized) {
        //data['message'];
        result.status = StockLookupStatus.invalidApiKey;
        return result;
      }

      if (data['code'] == _httpForbidden || data['code'] == _httpNotFound) {
        // SYMBOL NOT FOUND
        result.status = StockLookupStatus.invalidSymbol;
        return result;
      }

      if (data['code'] == _httpConflict) {
        // API error
        // You have run out of API credits for the current minute. 9 API credits were used, with the current limit being 8. Wait for the new...
        result.status = StockLookupStatus.invalidApiKey;
        return result;
      }
      final List<dynamic> values = data['values'] as List<dynamic>;

      // Unfortunately for now (sometimes) the API may returns two entries with the same date
      // for this ensure that we only have one date and price, last one wins
      final Map<String, StockDatePrice> mapByUniqueDate = <String, StockDatePrice>{};

      for (final dynamic value in values) {
        final String dateAsText = value['datetime'] as String;

        final StockDatePrice sp = StockDatePrice(
          date: DateTime.parse(dateAsText),
          price: double.parse(value['close'] as String),
        );
        mapByUniqueDate[dateAsText] = sp;
      }

      // this will ensure that we only have one value per dates
      for (final StockDatePrice sp in mapByUniqueDate.values) {
        result.prices.add(sp);
      }
    } catch (error) {
      logger.e(error.toString());
    }
  } else {
    result.errorMessage = response.body.toString();
  }
  return result;
}

/// Saves stock price history for [symbol] to local preferences cache.
void _saveToCache(final String symbol, List<StockDatePrice> prices) async {
  // CSV Header
  String csvContent = '"date","price"\n';

  // Sheet Content
  for (final StockDatePrice item in prices) {
    csvContent += '${dateToString(item.date)},${item.price.toString()}\n';
  }

  await PreferenceController.to.setString('stock-$symbol', csvContent);
  await PreferenceController.to.setString(
    'stock-date-$symbol',
    DateTime.now().toIso8601String(),
  );

  // Also save to the last price to the Security table
  final Security? security = Data().securities.getBySymbol(symbol);
  if (security != null) {
    if (security.fieldPriceDate.value == null || prices.first.date.isAfter(security.fieldPriceDate.value!)) {
      // update to the last known stock price

      security.stashValueBeforeEditing();
      security.fieldPrice.setValue!(security, prices.first.price);
      security.fieldLastPrice.setValue!(security, prices.first.price);
      security.fieldPriceDate.setValue!(security, prices.first.date);
      Data().notifyMutationChanged(
        mutation: MutationType.changed,
        moneyObject: security,
        recalculateBalances: true,
      );
    }
  }
}

/// Marks [symbol] as an invalid stock symbol in the local cache.
void _saveToCacheInvalidSymbol(final String symbol) async {
  await PreferenceController.to.setString('stock-$symbol', flagAsInvalidSymbol);
}
