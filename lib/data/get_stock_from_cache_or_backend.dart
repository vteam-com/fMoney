import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:money/controller/preferences_controller.dart';
import 'package:money/data/data.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/models/money_objects/securities/security.dart';
import 'package:money/widgets/snack_bar.dart';

class StockDatePrice {
  /// Constructor
  const StockDatePrice({required this.date, required this.price});

  final DateTime date;
  final double price;
}

const String flagAsInvalidSymbol = 'invalid-symbol';

class StockPriceHistoryCache {
  StockPriceHistoryCache(this.symbol, this.status, [this.lastDateTime]);

  String errorMessage = '';
  List<StockDatePrice> prices = <StockDatePrice>[];
  StockLookupStatus status = StockLookupStatus.notFoundInCache;
  String symbol = '';

  DateTime? lastDateTime;
}

Future<StockPriceHistoryCache> getFromCacheOrBackend(String symbol) async {
  symbol = symbol.toLowerCase();

  StockPriceHistoryCache result = await _loadFromCache(symbol);

  if (result.status != StockLookupStatus.foundInCache) {
    // Try to load from the cloud service
    result = await loadFomBackendAndSaveToCache(symbol);
  }

  return result;
}

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

    for (int row = 0; row < csvLines.length; row++) {
      if (row == 0) {
        // skip header
      } else {
        final List<String> twoColumns = csvLines[row].split(',');
        if (twoColumns.length == 2) {
          final StockDatePrice sp = StockDatePrice(
            date: DateTime.parse(twoColumns[0]),
            price: double.parse(twoColumns[1]),
          );
          stockPriceHistoryCache.prices.add(sp);
        }
      }
    }
    return stockPriceHistoryCache;
  }
  return StockPriceHistoryCache(symbol, StockLookupStatus.notFoundInCache);
}

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
    const Duration(days: 365 * 40),
  );

  final String url =
      'https://api.twelvedata.com/time_series?symbol=$symbol&interval=1day&start_date=${numberOfDaysInThePast.toIso8601String()}&apikey=${PreferenceController.to.apiKeyForStocks}';

  final Uri uri = Uri.parse(url);

  if (symbol == Constants.mockStockSymbol) {
    result.prices = <StockDatePrice>[];
    return result;
  }

  final http.Response response = await http.get(uri);

  if (response.statusCode == 200) {
    try {
      final MyJson data = json.decode(response.body) as MyJson;
      if (data['code'] == 401) {
        //data['message'];
        result.status = StockLookupStatus.invalidApiKey;
        return result;
      }

      if (data['code'] == 403 || data['code'] == 404) {
        // SYMBOL NOT FOUND
        result.status = StockLookupStatus.invalidSymbol;
        return result;
      }

      if (data['code'] == 409) {
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

void _saveToCacheInvalidSymbol(final String symbol) async {
  await PreferenceController.to.setString('stock-$symbol', flagAsInvalidSymbol);
}
