import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPermissionState { notAsked, granted, denied }

class NotificationSettings {
  static const String _enabledKey = 'notifications_enabled';
  static const String _timeKey = 'notification_time_minutes';
  static const String _permissionStateKey = 'notifications_permission_state';
  static const String _permissionRequestedKey = 'notifications_permission_requested';
  static const TimeOfDay defaultTime = TimeOfDay(hour: 8, minute: 0);

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
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

  static Future<bool> hasRequestedPermission() async {
    final state = await getPermissionState();
    return state != NotificationPermissionState.notAsked;
  }

  static Future<NotificationPermissionState> getPermissionState() async {
    final prefs = await SharedPreferences.getInstance();
    final rawState = prefs.getInt(_permissionStateKey);
    if (rawState != null &&
        rawState >= 0 &&
        rawState < NotificationPermissionState.values.length) {
      return NotificationPermissionState.values[rawState];
    }

    // Migration path for older builds that only stored "requested".
    final requested = prefs.getBool(_permissionRequestedKey) ?? false;
    if (!requested) {
      return NotificationPermissionState.notAsked;
    }

    final enabled = prefs.getBool(_enabledKey) ?? false;
    final migratedState =
        enabled
            ? NotificationPermissionState.granted
            : NotificationPermissionState.denied;
    await prefs.setInt(_permissionStateKey, migratedState.index);
    return migratedState;
  }

  static Future<void> setPermissionState(NotificationPermissionState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_permissionStateKey, state.index);
    await prefs.setBool(_permissionRequestedKey, true);
  }

  static Future<void> setPermissionRequested() async {
    await setPermissionState(NotificationPermissionState.denied);
  }
}
