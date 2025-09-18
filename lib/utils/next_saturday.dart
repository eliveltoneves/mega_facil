import 'package:timezone/timezone.dart' as tz;

DateTime saturdayNoonBRT(DateTime nowUtc) {
  // use nowUtc = DateTime.now().toUtc(); configure tz.getLocation('America/Sao_Paulo') no app/bootstrap se quiser precisão por horário de verão histórico
  final now = nowUtc.toLocal();
  var d = now;
  while (d.weekday != DateTime.saturday) {
    d = d.add(const Duration(days: 1));
  }
  return DateTime(d.year, d.month, d.day, 12, 0); // local
}
