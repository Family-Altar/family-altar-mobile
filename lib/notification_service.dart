import 'package:family_altar/navigation_service.dart';
import 'package:family_altar/notification_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Future.microtask(() async {
      try {
        await NotificationService().initAndScheduleDaily();
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
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initAndScheduleDaily() async {
    // 1) Init
    const androidInit = AndroidInitializationSettings('ic_notification');
    const iosInit = DarwinInitializationSettings();
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

    // 2) Android 13+ runtime permission (won't exist on older versions)
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await android
        ?.requestNotificationsPermission(); // docs show this pattern  [oai_citation:3‡Dart packages](https://pub.dev/packages/flutter_local_notifications)

    // 3) Timezone
    tz.initializeTimeZones();
    final tzInfo =
        await FlutterTimezone.getLocalTimezone(); // TimezoneInfo  [oai_citation:4‡Dart packages](https://pub.dev/packages/flutter_timezone)
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    // 4) Schedule — SAFER default: use inexact if exact alarms are restricted
    final time = await NotificationSettings.getTimeOfDay();
    final next = _nextInstanceOf(time.hour, time.minute);

    try {
      await _plugin.zonedSchedule(
        1,
        'Your daily reading is ready',
        "Take a moment with God's Word",
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel',
            'Daily reminders',
            channelDescription: 'Daily reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        matchDateTimeComponents: DateTimeComponents.time,

        // If you keep exactAllowWhileIdle, this can throw on Android 12+/14+ depending on permissions/settings
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e, st) {
      debugPrint('Exact schedule failed: $e');
      debugPrint('$st');

      await _plugin.zonedSchedule(
        1,
        'Your daily reading is ready',
        "Take a moment with God's Word",
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel',
            'Daily reminders',
            channelDescription: 'Daily reminder notifications',
          ),
        ),
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexact,
      );
    }
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
