// ignore_for_file: unnecessary_this
// ignore: fcheck_one_class_per_file
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:money/data/models/dividend_model.dart';
import 'package:money/data/models/stock_date_price_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/shared/domain/stock_split_entity.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/stock_cache_lookup_service.dart';
import 'package:money/widgets/charts/chart_event_model.dart';
import 'package:money/widgets/charts/my_line_chart.dart';
import 'package:money/widgets/dialogs/single_text_input_dialog.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/pure/working_indicator_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';

/// Module-level cache of the most recently fetched stock prices per symbol.
/// This persists across widget instances so that prices remain accurate even when
/// widgets are recreated during navigation or Data().updateAll() operations.
/// Key: symbol (lowercase), Value: most recently fetched price cache
final Map<String, StockPriceHistoryCache> _recentlyFetchedPrices = <String, StockPriceHistoryCache>{};

const int _httpOkStatus = 200;
const int _httpUnauthorized = 401;
const int _httpForbidden = 403;
const int _httpNotFound = 404;
const int _httpConflict = 409;
const List<int> _apiErrorCodes = <int>[_httpUnauthorized, _httpForbidden, _httpNotFound, _httpConflict];
const int _epochMillisPerSecond = 1000;
const int _zeroInt = 0;
const int _oneInt = 1;
const double _zeroDouble = 0.0;
const double _chartMarginLeft = 80.0;
const double _chartMarginBottom = 50.0;
const double _lineRectWidth = 0.5;
const double _labelLineHeight = 0.7;
const double _labelMaxWidth = 400.0;
const double _gridLineOffsetY = 5.0;
const double _gridLineHeight = 45.0;
const double _labelOffsetX = 2.0;
const double _labelOffsetY = 30.0;
const double _labelStepX = 20.0;
const int _lineAlpha = 150;
const int _boxAlpha = 100;
const double _activityBoxHeight = 20.0;
const double _activityLineOpacity = 0.8;

/// A stateful widget for stock chart widget.
class StockChartWidget extends StatefulWidget {
  const StockChartWidget({
    super.key,
    required this.symbol,
    required this.splits,
    required this.dividends,
    required this.holdingsActivities,
  });

  final List<Dividend> dividends;
  final List<ChartEvent> holdingsActivities;
  final List<StockSplit> splits;
  final String symbol;

  @override
  // ignore: library_private_types_in_public_api
  State<StockChartWidget> createState() => _StockChartWidgetState();
}

class _StockChartWidgetState extends State<StockChartWidget> {
  bool _refreshing = false;

  List<FlSpot> dataPoints = <FlSpot>[];

  StockPriceHistoryCache latestPriceHistoryData = StockPriceHistoryCache(
    '',
    StockLookupStatus.notFoundInCache,
    null,
  );

  late Security? security = Data().securities.getBySymbol(widget.symbol);

  @override
  void initState() {
    super.initState();
    _getStockHistoricalData();
  }

  @override
  Widget build(BuildContext context) {
    if (security == null) {
      return CenterMessage(
        message: AppL10n.tr(
          AppTranslationKeys.securitySymbolInvalid,
          params: <String, String>{'symbol': widget.symbol},
        ),
      );
    }

    if (PreferenceController.to.apiKeyForStocks == Constants.fakeStockApiKey) {
      latestPriceHistoryData.status = StockLookupStatus.foundInCache;
    } else {
      if (PreferenceController.to.apiKeyForStocks.isEmpty ||
          latestPriceHistoryData.status == StockLookupStatus.invalidApiKey) {
        return Center(
          child: ElevatedButton(
            onPressed: () {
              showTextInputDialog(
                context: context,
                title: AppL10n.tr(AppTranslationKeys.setApiKey),
                subTitle: AppL10n.tr(AppTranslationKeys.forAccessingTwelveData),
                initialValue: PreferenceController.to.apiKeyForStocks,
                onContinue: (String text) {
                  PreferenceController.to.apiKeyForStocks = text;
                },
              );
            },
            child: Text(AppL10n.tr(AppTranslationKeys.setApiKey)),
          ),
        );
      }
    }

    switch (latestPriceHistoryData.status) {
      case StockLookupStatus.foundInCache:
      case StockLookupStatus.validSymbol:
      case StockLookupStatus.invalidSymbol:
        return _buildChart();
      default:
        return const WorkingIndicator();
    }
  }

  /// Converts price history cache into chart data points for visualization.
  void fromPriceHistoryToChartDataPoints(StockPriceHistoryCache priceCache) {
    if (priceCache.status == StockLookupStatus.validSymbol || priceCache.status == StockLookupStatus.foundInCache) {
      final List<FlSpot> tmpDataPoints = <FlSpot>[];
      for (final StockDatePrice sp in priceCache.prices) {
        tmpDataPoints.add(
          FlSpot(sp.date.millisecondsSinceEpoch.toDouble(), sp.price),
        );
      }
      if (mounted) {
        setState(() {
          this.latestPriceHistoryData = priceCache;
          this.dataPoints = tmpDataPoints;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          this.latestPriceHistoryData = priceCache;
          this.dataPoints = <FlSpot>[];
        });
      }
    }
  }

  /// Inserts a point for the first activity date if the price history starts later.
  void _adjustMissingDataPointInThePast() {
    for (final ChartEvent activity in widget.holdingsActivities.reversed) {
      if (dataPoints.isEmpty || activity.dates.min!.millisecondsSinceEpoch < dataPoints.first.x) {
        dataPoints.insert(
          _zeroInt,
          FlSpot(
            activity.dates.min!.millisecondsSinceEpoch.toDouble(),
            activity.amount,
          ),
        );
      }
    }
  }

  /// Builds the stock chart with overlays for splits, activities, dividends, and current price.
  Widget _buildChart() {
    // Date ascending
    dataPoints.sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));

    _adjustMissingDataPointInThePast();

    if (dataPoints.isEmpty) {
      return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noDataPoints));
    }

    // lines are drawn let to right sorted by time
    // the labels are drawn bottom to top sorted by ascending currentUnitPrice
    widget.holdingsActivities.sort(
      (ChartEvent a, ChartEvent b) => a.amount.compareTo(b.amount),
    );

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        // Splits
        Padding(
          padding: const EdgeInsets.only(
            left: _chartMarginLeft,
            bottom: _chartMarginBottom,
          ),
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _PaintSplits(
              splits: widget.splits,
              minX: dataPoints.first.x,
              maxX: dataPoints.last.x,
            ),
          ),
        ),

        // Activities Buy & Sell
        Padding(
          padding: const EdgeInsets.only(
            left: _chartMarginLeft,
            bottom: _chartMarginBottom,
          ),
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: PaintActivities(
              activities: widget.holdingsActivities,
              minX: dataPoints.first.x,
              maxX: dataPoints.last.x,
            ),
          ),
        ),

        // Dividends
        Padding(
          padding: const EdgeInsets.only(
            left: _chartMarginLeft,
            bottom: _chartMarginBottom,
          ),
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _PaintDividends(
              list: widget.dividends,
              minX: dataPoints.first.x,
              maxX: dataPoints.last.x,
            ),
          ),
        ),
        MyLineChart(dataPoints: dataPoints, showDots: false),

        /// Price and Refresh button
        Padding(
          padding: const EdgeInsets.only(
            left: _chartMarginLeft,
            bottom: _chartMarginBottom,
          ),
          child: _buildPriceRefreshButton(),
        ),
      ],
    );
  }

  /// Builds the current price display and refresh button.
  Widget _buildPriceRefreshButton() {
    if (dataPoints.isEmpty) {
      return CenterMessage(
        message: AppL10n.tr(
          AppTranslationKeys.noHistoryInformationAboutSymbol,
          params: <String, String>{'symbol': widget.symbol},
        ),
      );
    }
    return scaleDown(
      IntrinsicWidth(
        child: TextButton(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SizeForPadding.medium,
                ),
                child: Text(
                  '${widget.symbol} ${doubleToCurrency(dataPoints.last.y)}',
                  style: const TextStyle(fontSize: SizeForText.large),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SizeForPadding.medium,
                ),
                child: _refreshing ? const CupertinoActivityIndicator() : const Icon(Icons.refresh_outlined),
              ),
              Text(getElapsedTime(latestPriceHistoryData.lastDateTime)),
            ],
          ),
          onPressed: () async {
            setState(() {
              _refreshing = true;
            });
            try {
              final StockPriceHistoryCache priceResult = await loadFomBackendAndSaveToCache(widget.symbol);
              // Cache fresh price at module level so it survives widget recreation
              _recentlyFetchedPrices[widget.symbol.toLowerCase()] = priceResult;
              fromPriceHistoryToChartDataPoints(priceResult);

              // Fetch Historical Stock Splits
              List<StockSplit> splits = <StockSplit>[];
              if (PreferenceController.to.useYahooStock) {
                splits = await _fetchStockSplitsFromYahoo(widget.symbol);
              } else {
                splits = await _fetchSplitsFromTwelveData(widget.symbol);
              }
              if (mounted) {
                final bool shouldUpdateAll = DataFileController.to.trackMutations.isMutated();
                setState(() {
                  _refreshing = false;

                  // update the data model
                  Data().stockSplits.setStockSplits(security!.uniqueId, splits);
                });

                // Call updateAll AFTER setState completes to avoid destroying widget mid-render
                if (shouldUpdateAll) {
                  Data().updateAll();
                }
              }
            } catch (error) {
              if (mounted) {
                setState(() {
                  _refreshing = false;
                });
              }
              logger.e('Failed to refresh stock price: $error');
            }
          },
        ),
      ),
    );
  }

  /// Fetches stock split history from TwelveData and converts it into [StockSplit] models.
  Future<List<StockSplit>> _fetchSplitsFromTwelveData(String symbol) async {
    final List<StockSplit> splitsFound = <StockSplit>[];

    if (PreferenceController.to.apiKeyForStocks.isNotEmpty) {
      final Uri uri = Uri.parse(
        'https://api.twelvedata.com/splits?symbol=$symbol&range=full&apikey=${PreferenceController.to.apiKeyForStocks}',
      );

      final http.Response response = await http.get(uri);

      if (response.statusCode == _httpOkStatus) {
        try {
          final MyJson data = json.decode(response.body) as MyJson;

          final int? subStatusCode = data['code'] as int?;
          if (_apiErrorCodes.contains(subStatusCode)) {
            logger.e(data.toString());
            SnackBarService.displayError(message: data['message'] as String);
          } else {
            final List<dynamic> dataSplits = data['splits'] as List<dynamic>;

            final int securityId = Data().securities.getBySymbol(symbol)!.uniqueId;
            for (final dynamic dataSplit in dataSplits) {
              final DateTime dateOfSplit = DateTime.parse(
                dataSplit['date'] as String,
              );
              final StockSplit sp = StockSplit(
                security: securityId,
                date: dateOfSplit,
                numerator: dataSplit['from_factor'] as int,
                denominator: dataSplit['to_factor'] as int,
                data: Data(),
              );
              splitsFound.add(sp);
            }
          }
        } catch (error) {
          logger.e(error.toString());
          SnackBarService.displayError(message: error.toString());
        }
      } else {
        logger.e('Failed to fetch data: ${response.toString()}');
      }
    }
    return splitsFound;
  }

  /// Fetches stock split history from Yahoo Finance and converts it into [StockSplit] models.
  Future<List<StockSplit>> _fetchStockSplitsFromYahoo(String symbol) async {
    final List<StockSplit> splitsFound = <StockSplit>[];

    // Base URL for Yahoo Finance API v8
    final String baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/$symbol';

    // Define the query parameters
    final Map<String, String> queryParams = <String, String>{
      'interval': '1d', // Daily interval
      'range': '5y', // Last 5 years range
      'events': SharedStrings.stockEventSplits, // Fetch stock splits
    };

    // Construct the full URL with query parameters
    final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    // Send the GET request to the Yahoo Finance API
    final http.Response response = await http.get(uri);

    // Check if the request was successful
    if (response.statusCode == _httpOkStatus) {
      // Parse the response body as JSON
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final Security? security = Data().securities.getBySymbol(symbol);
      if (security != null) {
        // Extract the stock splits data
        // ignore: always_specify_types
        final responseChart = jsonResponse['chart'];
        if (responseChart != null) {
          // ignore: always_specify_types
          final responseChartResult = responseChart['result'];
          if (responseChartResult != null) {
            if ((responseChartResult is List) && responseChartResult.isNotEmpty) {
              // ignore: always_specify_types
              final firstEntry = responseChartResult.firstOrNull;
              if (firstEntry != null) {
                // ignore: always_specify_types
                final events = firstEntry['events'];
                if (events != null) {
                  // ignore: always_specify_types
                  final MyJson? splits = events[SharedStrings.stockEventSplits] as MyJson?;
                  if (splits != null) {
                    // ignore: always_specify_types
                    for (var splitJson in splits.values) {
                      final int dateInMilliseconds = splitJson['date'] as int;
                      final DateTime dateOSplit = DateTime.fromMillisecondsSinceEpoch(
                        dateInMilliseconds * _epochMillisPerSecond,
                      );
                      final StockSplit sp = StockSplit(
                        security: security.uniqueId,
                        date: dateOSplit,
                        numerator: (splitJson['numerator'] as num).toInt(),
                        denominator: (splitJson['denominator'] as num).toInt(),
                        data: Data(),
                      );
                      splitsFound.add(sp);
                    }
                  }
                }
              }
            }
          }
        }
      } else {
        // Handle the error
        logger.e('Failed to load stock splits for $symbol');
      }
    }
    return splitsFound;
  }

  /// Loads stock historical price data from cache or backend.
  /// Prioritizes recently fetched prices to avoid overwriting fresh data with stale cache.
  /// Uses module-level cache first to handle widget recreation during navigation.
  Future<void> _getStockHistoricalData() async {
    // Check module-level cache first for recently fetched prices across widget instances
    // If found, use it and skip backend lookup to avoid stale data overwriting fresh data
    final StockPriceHistoryCache? cachedFreshPrice = _recentlyFetchedPrices[widget.symbol.toLowerCase()];
    if (cachedFreshPrice != null && cachedFreshPrice.prices.isNotEmpty) {
      fromPriceHistoryToChartDataPoints(cachedFreshPrice);
      return; // Don't call getFromCacheOrBackend - we have fresh data
    }

    // Fallback: load from SharedPreferences cache or backend
    final StockPriceHistoryCache priceCache = await getFromCacheOrBackend(
      widget.symbol,
    );
    fromPriceHistoryToChartDataPoints(priceCache);
  }
}

/// A reusable Paint object for drawing filled rectangles.
final ui.Paint _paint = Paint()..style = PaintingStyle.fill;

void _paintLine(
  ui.Canvas canvas,
  Color color,
  double left,
  double top,
  double chartHeight,
) {
  final ui.Rect rect = Rect.fromLTWH(left, top, _lineRectWidth, chartHeight);
  _paint.color = color;

  canvas.drawRect(rect, _paint);
}

/// Paints a text label at the given canvas coordinates.
void _paintLabel(
  ui.Canvas canvas,
  String text,
  Color color,
  double x,
  double y,
) {
  // Draw the text
  final TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: SizeForText.small,
        height: _labelLineHeight, // Tight lines spacing
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  );

  textPainter.layout(minWidth: _zeroDouble, maxWidth: _labelMaxWidth);

  textPainter.paint(canvas, Offset(x, y));
}

class _PaintSplits extends CustomPainter {
  _PaintSplits({required this.splits, required this.minX, required this.maxX});

  final double maxX;
  final double minX;
  final List<StockSplit> splits;

  @override
  void paint(Canvas canvas, Size size) {
    final double chartWidth = size.width;
    final double chartHeight = size.height;

    // lines are drawn lef to right sorted by time
    // the label are drawn bottom to top sorted by ascending amount
    for (final StockSplit split in splits) {
      double left = _zeroDouble;
      if (split.fieldDate.value!.millisecondsSinceEpoch > minX) {
        left = ((split.fieldDate.value!.millisecondsSinceEpoch - minX) / (maxX - minX)) * chartWidth;
      }
      _paintLine(canvas, Colors.grey, left, chartHeight - _gridLineOffsetY, _gridLineHeight);
      _paintLabel(
        canvas,
        AppL10n.tr(
          AppTranslationKeys.splitRatio,
          params: <String, String>{
            'numerator': getIntAsText(split.fieldNumerator.value),
            'denominator': getIntAsText(split.fieldDenominator.value),
          },
        ),
        Colors.blue,
        left + _labelOffsetX,
        chartHeight + _labelOffsetY,
      );
      left += _labelStepX;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// Represents paint activities.
class PaintActivities extends CustomPainter {
  PaintActivities({
    required this.activities,
    required this.minX,
    required this.maxX,
    this.lineColor,
  });

  final List<ChartEvent> activities;
  final Color? lineColor;
  final double maxX;
  final double minX;

  @override
  void paint(Canvas canvas, Size size) {
    final double chartWidth = size.width;
    final double chartHeight = size.height;

    final double labelVerticalDistribution = chartHeight / activities.length;
    double nextVerticalLabelPosition = chartHeight - labelVerticalDistribution;

    for (final ChartEvent activity in activities) {
      double left = _zeroDouble;
      double right = _zeroDouble;
      if (activity.dates.min!.millisecondsSinceEpoch > minX) {
        left = ((activity.dates.min!.millisecondsSinceEpoch - minX) / (maxX - minX)) * chartWidth;
      }
      if (activity.dates.max != null) {
        right = ((activity.dates.max!.millisecondsSinceEpoch - minX) / (maxX - minX)) * chartWidth;
      }
      _paintLine(
        canvas,
        lineColor?.withAlpha(_lineAlpha) ?? activity.colorToUse.withValues(alpha: _activityLineOpacity),
        left,
        _zeroDouble,
        chartHeight,
      );

      String text = '';
      // show the quantity if not 1
      if (activity.quantity.toInt().abs() != _oneInt) {
        text = '${getIntAsText(activity.quantity.toInt().abs())} ';
      }
      // show the value is not zero
      if (activity.amount != _zeroDouble) {
        text += doubleToCurrency(activity.amount, showPlusSign: true);
      }
      // add description
      if (activity.description.isNotEmpty) {
        text += '${SharedStrings.lineFeed}${activity.description}';
      }
      final Color boxColor = (lineColor ?? activity.colorToUse).withAlpha(_boxAlpha);
      Color textColor = boxColor;
      if (activity.dates.max != null) {
        _paintBox(
          canvas,
          left,
          nextVerticalLabelPosition,
          right - left,
          _activityBoxHeight,
          boxColor,
        );
        textColor = contrastColor(boxColor);
      }
      _paintLabel(canvas, text, textColor, left + _labelOffsetX, nextVerticalLabelPosition);

      nextVerticalLabelPosition -= labelVerticalDistribution;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  /// Draws a filled rectangle on the given [canvas] with the specified [color],
  /// [left], [top], [width], and [height].
  ///
  /// This function reuses a single [Paint] object for better performance.
  void _paintBox(
    ui.Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    Color color,
  ) {
    final ui.Rect rect = Rect.fromLTWH(left, top, width, height);
    final ui.Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);
  }
}

class _PaintDividends extends CustomPainter {
  _PaintDividends({required this.list, required this.minX, required this.maxX});

  final List<Dividend> list;
  final double maxX;
  final double minX;

  @override
  void paint(Canvas canvas, Size size) {
    final double chartWidth = size.width;
    final double chartHeight = size.height;

    // lines are drawn lef to right sorted by time
    // the label are drawn at bottom
    for (final Dividend item in list) {
      double left = _zeroDouble;
      if (item.date.millisecondsSinceEpoch > minX) {
        left = ((item.date.millisecondsSinceEpoch - minX) / (maxX - minX)) * chartWidth;
      }
      _paintLine(canvas, Colors.grey, left, chartHeight - _gridLineOffsetY, _gridLineHeight);
      _paintLabel(
        canvas,
        getAmountAsStringUsingCurrency(item.amount),
        Colors.green,
        left + _labelOffsetX,
        chartHeight + _labelOffsetY,
      );
      left += _labelStepX;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
