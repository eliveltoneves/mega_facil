import 'package:intl/intl.dart';

class TimeUtils {
  static String remainingStr(DateTime now, DateTime end) {
    final diff = end.difference(now);
    if (diff.isNegative) return 'Encerrado';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    return '${d}d ${h}h ${m}m';
  }

  static String fmtDate(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);
}
