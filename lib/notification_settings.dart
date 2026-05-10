import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  static const String _enabledKey = 'notifications_enabled';
  static const String _timeKey = 'notification_time_minutes';
  static const String _hasPromptedKey = 'notifications_has_prompted';
  static const TimeOfDay defaultTime = TimeOfDay(hour: 8, minute: 0);

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  static Future<bool> hasPromptedForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasPromptedKey) ?? false;
  }

  static Future<void> setHasPromptedForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPromptedKey, true);
  }

  static Future<TimeOfDay> getTimeOfDay() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_timeKey);
    if (minutes == null) {
      return defaultTime;
    }
    final normalized = minutes % (24 * 60);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  static Future<void> setTimeOfDay(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = (time.hour * 60) + time.minute;
    await prefs.setInt(_timeKey, minutes);
  }
}
