import 'package:intl/intl.dart';

/// A currency the user can track expenses in, identified by its ISO 4217 code.
class Currency {
  Currency._(this.code, this.name)
      : _format = NumberFormat.currency(name: code, symbol: '$code ');

  final String code;
  final String name;
  final NumberFormat _format;

  /// Shown before amount fields, e.g. "AED ".
  String get prefix => '$code ';

  /// Decimal places are taken from the currency (e.g. 0 for JPY).
  String format(double value) => _format.format(value);

  static final all = [
    for (final MapEntry(:key, :value) in _names.entries) Currency._(key, value)
  ];

  static final _byCode = {for (final c in all) c.code: c};

  static Currency? byCode(String? code) => _byCode[code];

  static final fallback = byCode('USD')!;

  /// Best guess from a locale like "en_IN"; falls back to USD.
  static Currency fromLocale(String locale) {
    try {
      return byCode(NumberFormat.simpleCurrency(locale: locale).currencyName) ??
          fallback;
    } catch (_) {
      return fallback;
    }
  }

  static const _names = {
    'AED': 'UAE Dirham',
    'ARS': 'Argentine Peso',
    'AUD': 'Australian Dollar',
    'BDT': 'Bangladeshi Taka',
    'BHD': 'Bahraini Dinar',
    'BRL': 'Brazilian Real',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CLP': 'Chilean Peso',
    'CNY': 'Chinese Yuan',
    'COP': 'Colombian Peso',
    'CZK': 'Czech Koruna',
    'DKK': 'Danish Krone',
    'EGP': 'Egyptian Pound',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'GHS': 'Ghanaian Cedi',
    'HKD': 'Hong Kong Dollar',
    'HUF': 'Hungarian Forint',
    'IDR': 'Indonesian Rupiah',
    'ILS': 'Israeli Shekel',
    'INR': 'Indian Rupee',
    'JOD': 'Jordanian Dinar',
    'JPY': 'Japanese Yen',
    'KES': 'Kenyan Shilling',
    'KRW': 'South Korean Won',
    'KWD': 'Kuwaiti Dinar',
    'LBP': 'Lebanese Pound',
    'LKR': 'Sri Lankan Rupee',
    'MAD': 'Moroccan Dirham',
    'MXN': 'Mexican Peso',
    'MYR': 'Malaysian Ringgit',
    'NGN': 'Nigerian Naira',
    'NOK': 'Norwegian Krone',
    'NPR': 'Nepalese Rupee',
    'NZD': 'New Zealand Dollar',
    'OMR': 'Omani Rial',
    'PEN': 'Peruvian Sol',
    'PHP': 'Philippine Peso',
    'PKR': 'Pakistani Rupee',
    'PLN': 'Polish Zloty',
    'QAR': 'Qatari Riyal',
    'RON': 'Romanian Leu',
    'RUB': 'Russian Ruble',
    'SAR': 'Saudi Riyal',
    'SEK': 'Swedish Krona',
    'SGD': 'Singapore Dollar',
    'THB': 'Thai Baht',
    'TRY': 'Turkish Lira',
    'TWD': 'Taiwan Dollar',
    'TZS': 'Tanzanian Shilling',
    'UAH': 'Ukrainian Hryvnia',
    'UGX': 'Ugandan Shilling',
    'USD': 'US Dollar',
    'VND': 'Vietnamese Dong',
    'ZAR': 'South African Rand',
  };
}
