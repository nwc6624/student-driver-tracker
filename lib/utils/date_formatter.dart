import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MM/dd/yy').format(date);
  }

  static String formatDateForDisplay(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  static String formatDay(DateTime date) {
    return '${date.day}';
  }
}
