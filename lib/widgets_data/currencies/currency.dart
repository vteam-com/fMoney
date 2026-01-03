import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/currency_label.dart';
import 'package:money/widgets_data/money_object.dart';

export 'package:intl/intl.dart';

/*
  cid  name         type          notnull  default  pk
  ---  -----------  ------------  -------  -------  --
  0    Id           INT           0                 1 
  1    Symbol       nchar(20)     1                 0 
  2    Name         nvarchar(80)  1                 0 
  3    Ratio        money         0                 0 
  4    LastRatio    money         0                 0 
  5    CultureCode  nvarchar(80)  0                 0 
 */
class Currency extends MoneyObject {
  Currency({
    required final int id, // 0
    required final String symbol, // 1
    required final String name, // 2
    required final double ratio, // 3
    required final String cultureCode, // 4
    required final double lastRatio, // 5
  }) {
    this.fieldId.value = id;
    this.fieldName.value = name;
    this.fieldSymbol.value = symbol;
    this.fieldRatio.value = ratio;
    this.fieldCultureCode.value = cultureCode;
    this.fieldLastRatio.value = lastRatio;
  }

  /// Constructor from a SQLite row
  factory Currency.fromJson(final MyJson row) {
    return Currency(
      // 0
      id: row.getInt('Id', -1),
      // 1
      symbol: row.getString('Symbol'),
      // 2
      name: row.getString('Name'),
      // 3
      ratio: row.getDouble('Ratio'),
      // 4
      lastRatio: row.getDouble('LastRatio'),
      // 5
      cultureCode: row.getString('CultureCode'),
    );
  }

  /// 5
  /// 5    CultureCode  nvarchar(80)
  FieldString fieldCultureCode = FieldString(
    name: 'Culture Code',
    serializeName: 'CultureCode',
    getValueForDisplay: (final MoneyObject instance) => (instance as Currency).fieldCultureCode.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Currency).fieldCultureCode.value,
  );

  // 0
  FieldId fieldId = FieldId(
    getValueForSerialization: (final MoneyObject instance) => instance.uniqueId,
  );

  // 4
  FieldDouble fieldLastRatio = FieldDouble(
    name: 'LastRatio',
    serializeName: 'LastRatio',
    getValueForDisplay: (final MoneyObject instance) => (instance as Currency).fieldLastRatio.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Currency).fieldLastRatio.value,
  );

  /// 2
  /// 2    name       nchar(20)
  FieldString fieldName = FieldString(
    name: 'Name',
    serializeName: 'Name',
    getValueForDisplay: (final MoneyObject instance) => (instance as Currency).fieldName.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Currency).fieldName.value,
  );

  /// 3    Ratio        money
  FieldDouble fieldRatio = FieldDouble(
    name: 'Ratio',
    serializeName: 'Ratio',
    getValueForDisplay: (final MoneyObject instance) => (instance as Currency).fieldRatio.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Currency).fieldRatio.value,
  );

  /// 1    Symbol       nchar(20)
  FieldString fieldSymbol = FieldString(
    name: 'Symbol',
    serializeName: 'Symbol',
    getValueForDisplay: (final MoneyObject instance) => (instance as Currency).fieldSymbol.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Currency).fieldSymbol.value,
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return fieldName.value;
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Currency> _fields = Fields<Currency>();

  /// Get the country code for flag from currency ISO code
  static String getCountryFromCurrencyIso4217(String iso4217code) {
    // Map currency codes to their flag country codes
    const Map<String, String> currencyFlags = <String, String>{
      'AED': 'ae',
      'AFN': 'af',
      'ALL': 'al',
      'AMD': 'am',
      'ANG': 'an',
      'AOA': 'ao',
      'ARS': 'ar',
      'AUD': 'au',
      'AWG': 'aw',
      'AZN': 'az',
      'BAM': 'ba',
      'BBD': 'bb',
      'BDT': 'bd',
      'BGN': 'bg',
      'BHD': 'bh',
      'BIF': 'bi',
      'BMD': 'bm',
      'BND': 'bn',
      'BOB': 'bo',
      'BOV': 'bo',
      'BRL': 'br',
      'BSD': 'bs',
      'BTN': 'bt',
      'BWP': 'bw',
      'BYN': 'by',
      'BYR': 'by',
      'BZD': 'bz',
      'CAD': 'ca',
      'CDF': 'cd',
      'CHE': 'ch',
      'CHF': 'ch',
      'CHW': 'ch',
      'CLF': 'cl',
      'CLP': 'cl',
      'CNY': 'cn',
      'COP': 'co',
      'COU': 'co',
      'CRC': 'cr',
      'CUC': 'cu',
      'CUP': 'cu',
      'CVE': 'cv',
      'CZK': 'cz',
      'DJF': 'dj',
      'DKK': 'dk',
      'DOP': 'do',
      'DZD': 'dz',
      'EGP': 'eg',
      'ERN': 'er',
      'ETB': 'et',
      'EUR': 'eu', // European Union flag
      'FJD': 'fj',
      'FKP': 'fk',
      'GBP': 'gb',
      'GEL': 'ge',
      'GHS': 'gh',
      'GIP': 'gi',
      'GMD': 'gm',
      'GNF': 'gn',
      'GTQ': 'gt',
      'GYD': 'gy',
      'HKD': 'hk',
      'HNL': 'hn',
      'HRK': 'hr',
      'HTG': 'ht',
      'HUF': 'hu',
      'IDR': 'id',
      'ILS': 'il',
      'INR': 'in',
      'IQD': 'iq',
      'IRR': 'ir',
      'ISK': 'is',
      'JMD': 'jm',
      'JOD': 'jo',
      'JPY': 'jp',
      'KES': 'ke',
      'KGS': 'kg',
      'KHR': 'kh',
      'KID': 'ki',
      'KMF': 'km',
      'KPW': 'kp',
      'KRW': 'kr',
      'KWD': 'kw',
      'KYD': 'ky',
      'KZT': 'kz',
      'LAK': 'la',
      'LBP': 'lb',
      'LKR': 'lk',
      'LRD': 'lr',
      'LSL': 'ls',
      'LYD': 'ly',
      'MAD': 'ma',
      'MDL': 'md',
      'MGA': 'mg',
      'MKD': 'mk',
      'MMK': 'mm',
      'MNT': 'mn',
      'MOP': 'mo',
      'MRO': 'mr',
      'MRU': 'mr',
      'MUR': 'mu',
      'MVR': 'mv',
      'MWK': 'mw',
      'MXN': 'mx',
      'MXV': 'mx',
      'MYR': 'my',
      'MZN': 'mz',
      'NAD': 'na',
      'NGN': 'ng',
      'NIO': 'ni',
      'NOK': 'no',
      'NPR': 'np',
      'NZD': 'nz',
      'OMR': 'om',
      'PAB': 'pa',
      'PEN': 'pe',
      'PGK': 'pg',
      'PHP': 'ph',
      'PKR': 'pk',
      'PLN': 'pl',
      'PYG': 'py',
      'QAR': 'qa',
      'RON': 'ro',
      'RSD': 'rs',
      'RUB': 'ru',
      'RWF': 'rw',
      'SAR': 'sa',
      'SBD': 'sb',
      'SCR': 'sc',
      'SDG': 'sd',
      'SEK': 'se',
      'SGD': 'sg',
      'SHP': 'sh',
      'SLL': 'sl',
      'SOS': 'so',
      'SRD': 'sr',
      'SSP': 'ss',
      'STD': 'st',
      'STN': 'st',
      'SVC': 'sv',
      'SYP': 'sy',
      'SZL': 'sz',
      'THB': 'th',
      'TJS': 'tj',
      'TMT': 'tm',
      'TND': 'tn',
      'TOP': 'to',
      'TRY': 'tr',
      'TTD': 'tt',
      'TWD': 'tw',
      'TZS': 'tz',
      'UAH': 'ua',
      'UGX': 'ug',
      'USD': 'us',
      'USN': 'us',
      'UYI': 'uy',
      'UYU': 'uy',
      'UZS': 'uz',
      'VEF': 've',
      'VES': 've',
      'VND': 'vn',
      'VUV': 'vu',
      'WST': 'ws',
      'XAF': 'xf',
      'XCD': 'xc',
      'XOF': 'xo',
      'XPF': 'xp',
      'YER': 'ye',
      'ZAR': 'za',
      'ZMW': 'zm',
      'ZWL': 'zw',
    };

    // Default to 'us' if the currency code is not found
    return currencyFlags[iso4217code] ?? 'us';
  }

  static Widget buildCurrencyWidget(String threeLetterCurrencySymbol) {
    final String flagId = getCountryFromCurrencyIso4217(threeLetterCurrencySymbol);

    return CurrencyLabel(
      threeLetterCurrencySymbol: getCurrencyAsString(threeLetterCurrencySymbol),
      flagId: flagId,
    );
  }

  static Fields<Currency> get fields {
    if (_fields.isEmpty) {
      final Currency tmp = Currency.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldSymbol,
        tmp.fieldName,
        tmp.fieldRatio,
        tmp.fieldLastRatio,
        tmp.fieldCultureCode,
      ]);
    }
    return _fields;
  }

  static String getCurrencyAsString(final String threeLetterCurrencySymbol) {
    if (threeLetterCurrencySymbol.isEmpty) {
      return Constants.defaultCurrency;
    }
    return threeLetterCurrencySymbol;
  }
}
