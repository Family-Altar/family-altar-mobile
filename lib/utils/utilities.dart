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
