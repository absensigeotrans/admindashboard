import 'package:intl/intl.dart';

DateTime utcToWIB(DateTime utc) {
  return utc.toUtc().add(const Duration(hours: 7));
}

String formatWIB(String? isoStr, {String format = 'HH:mm'}) {
  if (isoStr == null) return '-';
  try {
    final utc = DateTime.parse(isoStr).toUtc();
    final wib = utc.add(const Duration(hours: 7));
    return DateFormat(format).format(wib);
  } catch (_) {
    return isoStr;
  }
}

String formatDateWIB(String? isoStr, {String format = 'dd MMM yyyy'}) {
  if (isoStr == null) return '-';
  try {
    final utc = DateTime.parse(isoStr).toUtc();
    final wib = utc.add(const Duration(hours: 7));
    return DateFormat(format).format(wib);
  } catch (_) {
    return isoStr;
  }
}

DateTime dateFromUtcToWIB(String isoStr) {
  return DateTime.parse(isoStr).toUtc().add(const Duration(hours: 7));
}

String wibDateKey(String isoStr) {
  final wib = dateFromUtcToWIB(isoStr);
  return DateFormat('yyyy-MM-dd').format(wib);
}
