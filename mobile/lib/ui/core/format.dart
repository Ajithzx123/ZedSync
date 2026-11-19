import 'package:intl/intl.dart';

const _mask = '•••••';

class Fmt {
  static final _symbols = {'USD': r'$', 'EUR': '€', 'GBP': '£', 'INR': '₹'};

  static String money(double v, String ccy, {bool hidden = false, bool signed = false}) {
    if (hidden) return _mask;
    final f = NumberFormat.currency(symbol: _symbols[ccy] ?? '$ccy ', decimalDigits: 2);
    final s = f.format(v.abs());
    if (v < 0) return '-$s';
    return signed && v > 0 ? '+$s' : s;
  }

  static String price(double v) {
    final digits = v < 10 ? 5 : 2;
    return NumberFormat.decimalPatternDigits(decimalDigits: digits).format(v);
  }

  static String volume(double v) => NumberFormat('0.00##').format(v);

  static String ago(DateTime? t, {DateTime? now}) {
    if (t == null) return 'never';
    final d = (now ?? DateTime.now().toUtc()).difference(t);
    if (d.inSeconds < 5) return 'just now';
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  static String duration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  static String dateTime(DateTime t) => DateFormat('d MMM, HH:mm').format(t.toLocal());

  static String accountNumber(String n, {bool hidden = false}) =>
      hidden && n.length > 3 ? '••••${n.substring(n.length - 3)}' : n;
}
