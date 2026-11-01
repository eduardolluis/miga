/// Explicitly supported locale/currency DISPLAY options.
/// Automatic store prices remain available only for DO/DOP; selecting another
/// region never converts an amount or claims to know live local prices.
class SupportedRegion {
  const SupportedRegion(this.countryCode, this.name, this.currencyCode);
  final String countryCode;
  final String name;
  final String currencyCode;
}

abstract final class SupportedRegions {
  static const all = [
    SupportedRegion('DO', 'República Dominicana', 'DOP'),
    SupportedRegion('US', 'United States', 'USD'),
    SupportedRegion('MX', 'México', 'MXN'),
    SupportedRegion('CO', 'Colombia', 'COP'),
    SupportedRegion('ES', 'España', 'EUR'),
    SupportedRegion('CA', 'Canada', 'CAD'),
  ];

  static const currencies = ['DOP', 'USD', 'MXN', 'COP', 'EUR', 'CAD'];

  static bool validCurrency(String value) => currencies.contains(value);

  static SupportedRegion forCountry(String? value) =>
      all.firstWhere((r) => r.countryCode == value, orElse: () => all.first);

  static String symbol(String value) => switch (value) {
    'DOP' => 'RD\$',
    'USD' => 'US\$',
    'MXN' => 'MX\$',
    'COP' => 'COP\$',
    'EUR' => '€',
    'CAD' => 'CA\$',
    _ => '$value ',
  };

  static String format(
    String currency,
    double amount, {
    bool compact = false,
  }) =>
      '${symbol(currency)}${amount.toStringAsFixed(compact && amount == amount.roundToDouble() ? 0 : 2)}';
}
