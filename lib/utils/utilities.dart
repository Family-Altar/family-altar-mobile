import 'package:family_altar/models/volume.dart';
import 'package:family_altar/screens/reader/domain/reading.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  static String _lastAccessedKeyFor(Volume volume) =>
      'last_accessed_day${volume.storageSuffix}';

  static Future<DateTime?> getLastAccessedDay({
    Volume volume = Volume.one,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastAccessedKeyFor(volume));
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
    } on Exception {
      // fail silently
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

String formatReadingForSharing(
  Reading reading, {
  Volume volume = Volume.one,
}) {
  final scripture = reading.scripture.trim();
  final quote = reading.quote.trim();
  final dailyReading = reading.dailyReading.trim();
  final sermonTitleAndDate = reading.title.trim();

  final dailyReadingLabel =
      volume == Volume.two ? 'Parallel Scripture:' : 'Daily Reading:';

  final shareContent = '''
    |$scripture
    |
    |$quote\n
    |$sermonTitleAndDate
    |
    |$dailyReadingLabel
    |$dailyReading

  '''.stripMargin();

  final fullShareText = '''
    |Family Altar - ${volume.displayTitle}
    |${reading.date}
    |
    |$shareContent
  '''.stripMargin();

  return fullShareText;
}

String formatDateTypeToDDMMYYY(DateTime date) {
  return DateFormat('d MMMM yyyy').format(date);
}
