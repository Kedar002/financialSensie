import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _currencyFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compactFormat = NumberFormat.compact(locale: 'en_IN');

  static String currency(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _currencyFormatWithDecimals.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String currencyCompact(double amount) {
    if (amount.abs() < 1000) {
      return currency(amount);
    }
    return '₹${_compactFormat.format(amount)}';
  }

  static String percentage(double value, {int decimals = 0}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  static String months(double value) {
    if (value < 1) {
      final weeks = (value * 4).round();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
    }
    final roundedMonths = value.round();
    return '$roundedMonths ${roundedMonths == 1 ? 'month' : 'months'}';
  }

  static String date(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static String dateShort(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String daysRemaining(int days) {
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Today';
    if (days == 1) return '1 day left';
    if (days < 30) return '$days days left';
    final months = (days / 30).round();
    return '$months ${months == 1 ? 'month' : 'months'} left';
  }
}
