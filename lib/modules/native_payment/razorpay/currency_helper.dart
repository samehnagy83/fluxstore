/// Razorpay Docs - https://razorpay.com/docs/api/orders/create/
class RazorpayCurrencyHelper {
  // 3 decimal currencies
  static const Set<String> _threeDecimalCurrencies = {
    'BHD',
    'IQD',
    'JOD',
    'KWD',
    'OMR',
    'TND',
  };

  // 0 decimal currencies
  static const Set<String> _zeroDecimalCurrencies = {
    'BIF',
    'CLP',
    'DJF',
    'GNF',
    'ISK',
    'JPY',
    'KMF',
    'KRW',
    'PYG',
    'RWF',
    'UGX',
    'VND',
    'VUV',
    'XAF',
    'XOF',
    'XPF',
  };

  /// Format amount for Razorpay API based on currency decimal places
  static String formatAmount(String price, String currency) {
    final amount = double.parse(price);

    if (_zeroDecimalCurrencies.contains(currency)) {
      // 0 decimal currencies: JPY 99 → 99
      return amount.toInt().toString();
    } else if (_threeDecimalCurrencies.contains(currency)) {
      // 3 decimal currencies: KWD 99.999 → 99999
      return (amount * 1000).toInt().toString();
    } else {
      // 2 decimal currencies (default): USD 20.50 → 2050, INR 1000 → 100000
      return (amount * 100).toInt().toString();
    }
  }
}
