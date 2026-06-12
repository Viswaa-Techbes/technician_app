import 'package:intl/intl.dart';

/// Formatting helpers for currency, dates, etc.
class Formatters {
  Formatters._();

  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _inrFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format amount as ₹1,234
  static String currency(num amount) => _inrFormat.format(amount);

  /// Format amount as ₹1,234.56
  static String currencyDecimal(num amount) => _inrFormatDecimal.format(amount);

  /// Format as "12 Mar 2026"
  static String dateShort(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  /// Format as "12 Mar 2026, 2:30 PM"
  static String dateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, h:mm a').format(date);

  /// Format as "2:30 PM"
  static String time(DateTime date) => DateFormat('h:mm a').format(date);

  /// Format as "March 2026"
  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

  /// Relative time: "2 min ago", "1 hr ago", "Yesterday", etc.
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return dateShort(date);
  }
}
