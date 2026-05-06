import 'package:family_altar/navigation_service.dart';
import 'package:family_altar/notification_settings.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/storage/local_reading_storage.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
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
        await NotificationService().initOnLaunch();
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
  final _readingRepository = ReadingRepository(LocalReadingStorage());

  /// Called once per app launch. On first launch requests OS permission;
  /// on subsequent launches syncs enabled state with OS and reschedules.
  Future<void> initOnLaunch() async {
    await _initialize();
    await _createAndroidNotificationChannel();

    final permissionState = await NotificationSettings.getPermissionState();
    if (permissionState == NotificationPermissionState.notAsked) return;

    // Sync saved state with what the OS actually says (e.g. user toggled in
    // system settings since last launch).
    final osEnabled = await _areNotificationsAllowed();
    await NotificationSettings.setEnabled(enabled: osEnabled);
    if (osEnabled) {
      await _scheduleDaily();
    }
  }

  /// Ensures we have a persisted permission declaration.
  /// If no declaration exists, requests OS permission and stores the decision.
  Future<bool> ensurePermissionDeclaration() async {
    await _initialize();
    await _createAndroidNotificationChannel();

    final permissionState = await NotificationSettings.getPermissionState();
    if (permissionState != NotificationPermissionState.notAsked) {
      return await _areNotificationsAllowed();
    }

    return _requestAndPersistPermissionDecision();
  }

  /// Shows a themed, centered pre-permission dialog before the OS prompt.
  /// Stores a declaration in persistence regardless of allow/deny selection.
  Future<bool> ensurePermissionDeclarationWithPrompt(BuildContext context) async {
    await _initialize();
    await _createAndroidNotificationChannel();

    final permissionState = await NotificationSettings.getPermissionState();
    if (permissionState != NotificationPermissionState.notAsked) {
      return await _areNotificationsAllowed();
    }

    if (!context.mounted) {
      return false;
    }

    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: dialogContext.accent.withValues(alpha: 0.25),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: dialogContext.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enable daily reminders',
                  style: AppFonts.bold(dialogContext, size: FontSize.large),
                ),
              ),
            ],
          ),
          content: Text(
            'We can send a daily reminder for your Family Altar reading time.',
            style: AppFonts.normal(dialogContext, size: FontSize.small),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Not now',
                style: AppFonts.normal(
                  dialogContext,
                ).copyWith(color: dialogContext.textColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogContext.accent,
                foregroundColor: dialogContext.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Allow',
                style: AppFonts.bold(dialogContext, size: FontSize.small),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRequest == true) {
      return _requestAndPersistPermissionDecision();
    }

    await NotificationSettings.setPermissionState(
      NotificationPermissionState.denied,
    );
    await NotificationSettings.setEnabled(enabled: false);
    return false;
  }

  /// Called after the user changes their preferred time in Settings.
  Future<bool> initAndScheduleDaily() async {
    final enabled = await NotificationSettings.isEnabled();
    if (!enabled) {
      return false;
    }

    await _initialize();
    await _createAndroidNotificationChannel();

    final notificationsAllowed = await _areNotificationsAllowed();
    if (!notificationsAllowed) {
      await NotificationSettings.setEnabled(enabled: false);
      debugPrint('Notifications are not allowed by OS.');
      return false;
    }

    await _scheduleDaily();
    return true;
  }

  /// Toggle flow for Settings: always show app popup first, then request OS
  /// permission if user confirms.
  Future<bool> enableDailyNotificationsWithPrompt(BuildContext context) async {
    await _initialize();
    await _createAndroidNotificationChannel();

    if (!context.mounted) return false;
    final shouldRequest = await _showPermissionPrePrompt(context);
    if (!shouldRequest) {
      await NotificationSettings.setPermissionState(
        NotificationPermissionState.denied,
      );
      await NotificationSettings.setEnabled(enabled: false);
      return false;
    }

    final granted = await _requestNotificationsPermission();
    await NotificationSettings.setPermissionState(
      granted
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied,
    );
    await NotificationSettings.setEnabled(enabled: granted);
    if (!granted) {
      return false;
    }

    await _scheduleDaily();
    return true;
  }

  Future<void> disableDailyNotifications() async {
    await _initialize();
    await _plugin.cancel(_dailyNotificationId);
    await NotificationSettings.setEnabled(enabled: false);
  }

  Future<void> _initialize() async {
    const androidInit = AndroidInitializationSettings('ic_notification');
    // Disable auto-requesting on iOS so we control timing via
    // _requestNotificationsPermission().
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
        _plugin.resolvePlatformSpecificImplementation<
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
      final granted = await android.requestNotificationsPermission();
      // On Android versions below 13 there is no runtime notification prompt,
      // and plugins can return null for this call.
      return granted ?? true;
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

  Future<bool> _showPermissionPrePrompt(BuildContext context) async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: dialogContext.accent.withValues(alpha: 0.25),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: dialogContext.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enable daily reminders',
                  style: AppFonts.bold(dialogContext, size: FontSize.large),
                ),
              ),
            ],
          ),
          content: Text(
            'We can send a daily reminder for your Family Altar reading time.',
            style: AppFonts.normal(dialogContext, size: FontSize.small),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Not now',
                style: AppFonts.normal(
                  dialogContext,
                ).copyWith(color: dialogContext.textColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogContext.accent,
                foregroundColor: dialogContext.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Allow',
                style: AppFonts.bold(dialogContext, size: FontSize.small),
              ),
            ),
          ],
        );
      },
    );

    return shouldRequest ?? false;
  }

  Future<bool> _requestAndPersistPermissionDecision() async {
    final granted = await _requestNotificationsPermission();
    await NotificationSettings.setPermissionState(
      granted
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied,
    );
    await NotificationSettings.setEnabled(enabled: granted);
    return granted;
  }

  Future<bool> _areNotificationsAllowed() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
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
    final body = await _buildDailyNotificationBody();

    await _plugin.zonedSchedule(
      _dailyNotificationId,
      'Your daily reading is ready',
      body,
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
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<String> _buildDailyNotificationBody() async {
    const fallbackMessage = "Take a moment with God's Word";

    try {
      final reading = await _readingRepository.fetchReading(date: DateTime.now());
      final sourceText =
          reading.quote.trim().isNotEmpty
              ? reading.quote
              : reading.dailyReading.trim();

      final preview = _truncateToWords(sourceText, 100);
      if (preview.isEmpty) {
        return fallbackMessage;
      }
      return preview;
    } catch (e, st) {
      debugPrint('Failed to build notification preview: $e');
      debugPrint('$st');
      return fallbackMessage;
    }
  }

  String _truncateToWords(String value, int maxWords) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '';
    }

    final words = normalized.split(' ');
    if (words.length <= maxWords) {
      return normalized;
    }

    return '${words.take(maxWords).join(' ')}...';
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
