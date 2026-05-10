import 'package:family_altar/navigation_service.dart';
import 'package:family_altar/notification_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationBootstrapper extends StatefulWidget {
  const NotificationBootstrapper({required this.child, super.key});
  final Widget child;

  @override
  State<NotificationBootstrapper> createState() =>
      _NotificationBootstrapperState();
}

class _NotificationBootstrapperState extends State<NotificationBootstrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final hasPrompted =
            await NotificationSettings.hasPromptedForPermission();
        if (!hasPrompted) {
          // First launch: mark as prompted before asking so a crash/kill during
          // the dialog doesn't result in repeated prompts on next open.
          await NotificationSettings.setHasPromptedForPermission();
          await NotificationService().enableDailyNotifications();
        } else {
          await NotificationService().initAndScheduleDaily();
        }
      } catch (e, st) {
        debugPrint('Notification init failed: $e');
        debugPrint('$st');
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class NotificationService {
  static const int _dailyNotificationId = 1;
  static const String _dailyChannelId = 'daily_channel';
  static const String _dailyChannelName = 'Daily reminders';
  static const String _dailyChannelDescription = 'Daily reminder notifications';

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<bool> initAndScheduleDaily() async {
    final enabled = await NotificationSettings.isEnabled();
    if (!enabled) {
      return false;
    }

    await _initialize();
    await _createAndroidNotificationChannel();

    final notificationsAllowed = await _areNotificationsAllowed();
    if (!notificationsAllowed) {
      debugPrint('Notifications are not allowed.');
      return false;
    }

    await _scheduleDaily();
    return true;
  }

  Future<bool> enableDailyNotifications() async {
    await _initialize();
    await _createAndroidNotificationChannel();

    final notificationPermissionGranted =
        await _requestNotificationsPermission();
    if (!notificationPermissionGranted) {
      await NotificationSettings.setEnabled(enabled: false);
      await _plugin.cancel(_dailyNotificationId);
      debugPrint('Notification permission was not granted.');
      return false;
    }

    await NotificationSettings.setEnabled(enabled: true);
    await _scheduleDaily();
    return true;
  }

  Future<void> disableDailyNotifications() async {
    await _initialize();
    await NotificationSettings.setEnabled(enabled: false);
    await _plugin.cancel(_dailyNotificationId);
  }

  Future<void> _initialize() async {
    const androidInit = AndroidInitializationSettings('ic_notification');
    // Disable the auto-request flags so the OS dialog only fires when the user
    // explicitly enables notifications via the settings toggle, not on every
    // cold start. The explicit request happens in
    // _requestNotificationsPermission.
    // Package defaults keep defaultPresent* true so notifications show in the
    // foreground on iOS (it suppresses them otherwise).
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {
        navigateToTodayReading();
      },
    );
  }

  Future<void> _createAndroidNotificationChannel() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dailyChannelId,
        _dailyChannelName,
        description: _dailyChannelDescription,
        importance: Importance.max,
      ),
    );
  }

  Future<bool> _requestNotificationsPermission() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      // requestNotificationsPermission() returns true immediately (no dialog)
      // if permission is already granted, and shows the OS dialog otherwise.
      // If it returns false/null (e.g. activity context unavailable on some
      // versions), fall back to areNotificationsEnabled() as the authoritative
      // check — that call only needs applicationContext, not an activity.
      final granted = await android.requestNotificationsPermission();
      if (granted ?? false) return true;
      return (await android.areNotificationsEnabled()) ?? false;
    }

    final ios =
        _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  Future<bool> _areNotificationsAllowed() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<void> _scheduleDaily() async {
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    final time = await NotificationSettings.getTimeOfDay();
    final next = _nextInstanceOf(time.hour, time.minute);

    await _plugin.zonedSchedule(
      _dailyNotificationId,
      'Your daily reading is ready',
      "Take a moment with God's Word",
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          channelDescription: _dailyChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
