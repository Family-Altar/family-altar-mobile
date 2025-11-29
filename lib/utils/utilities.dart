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

  static String unindent(String text) {
    final lines = text.split('\n');
    final indent = lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.length - l.trimLeft().length)
        .fold<int>(999, (a, b) => b < a ? b : a);

    return lines
        .map((l) => l.length >= indent ? l.substring(indent) : l)
        .join('\n');
  }
}
