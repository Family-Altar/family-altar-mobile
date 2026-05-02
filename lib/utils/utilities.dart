import 'package:family_altar/screens/reader/domain/reading.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  static const String _lastAccessedKey = 'last_accessed_day';

  static Future<DateTime?> getLastAccessedDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastAccessedKey);
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
    } on Exception {
      // Error getting last accessed day - fail silently
    }
    return null;
  }
}

extension StripMargin on String {
  String stripMargin([String margin = '|']) {
    return split('\n')
        .map((line) {
          final index = line.indexOf(margin);
          return index >= 0 ? line.substring(index + margin.length) : line;
        })
        .join('\n');
  }
}

String formatReadingForSharing(Reading reading) {
  final scripture = reading.scripture.replaceAll('\n', '').trim();
  final quote = reading.quote.replaceAll('\n', '').trim();
  final dailyReading = reading.dailyReading.replaceAll('\n', '').trim();
  final sermonTitleAndDate = reading.title.replaceAll('\n', '').trim();

  final shareContent =
      '''
    |$scripture
    |
    |$quote\n
    |$sermonTitleAndDate
    |
    |Daily Reading:
    |$dailyReading

  '''.stripMargin();

  final fullShareText =
      '''
    |Family Altar - Volume I
    |${reading.date}
    |
    |$shareContent
  '''.stripMargin();

  return fullShareText;
}

String formatDateTypeToDDMMYYY(DateTime date) {
  return DateFormat('d MMMM yyyy').format(date);
}
