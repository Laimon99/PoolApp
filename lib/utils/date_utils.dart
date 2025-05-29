import 'package:intl/intl.dart';

const _italianDays = {
  'Monday': 'Lunedì',
  'Tuesday': 'Martedì',
  'Wednesday': 'Mercoledì',
  'Thursday': 'Giovedì',
  'Friday': 'Venerdì',
  'Saturday': 'Sabato',
  'Sunday': 'Domenica',
};

String formatItalianDate(DateTime d) {
  final day = _italianDays[DateFormat('EEEE').format(d)] ?? '';
  return '$day ${d.day} ${DateFormat('MMMM', 'it_IT').format(d)}';
}
