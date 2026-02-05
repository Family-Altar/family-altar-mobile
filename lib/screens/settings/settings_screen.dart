import 'package:family_altar/notification_service.dart';
import 'package:family_altar/notification_settings.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ThemeOption {
  const ThemeOption({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final ThemeMode value;
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<ThemeOption> themeOptions = [
    ThemeOption(
      title: 'Light',
      subtitle: 'Always use light theme',
      value: ThemeMode.light,
    ),
    ThemeOption(
      title: 'Dark',
      subtitle: 'Always use dark theme',
      value: ThemeMode.dark,
    ),
    ThemeOption(
      title: 'System',
      subtitle: 'Follow system theme',
      value: ThemeMode.system,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: context.appBarColor,
        title: Text('Settings', style: AppFonts.bold(context)),
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
            size: AppIcons.getIconSize(IconSize.medium),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: context.backgroundColor.withValues(alpha: 0.8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: context.accent,
                          size: AppIcons.getIconSize(IconSize.medium),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Theme Settings',
                          style: AppFonts.bold(context, size: FontSize.large),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    BlocBuilder<ThemeBloc, ThemeState>(
                      builder: (context, state) {
                        final currentMode = state.themeMode;

                        return RadioGroup<ThemeMode>(
                          groupValue: currentMode,
                          onChanged: (value) {
                            if (value != null) {
                              context.read<ThemeBloc>().add(
                                    ThemeSetEvent(value),
                                  );
                            }
                          },
                          child: Column(
                            children: themeOptions.map((option) {
                              final isSelected = currentMode == option.value;

                              return RadioListTile<ThemeMode>.adaptive(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                title: Text(
                                  option.title,
                                  style: AppFonts.normal(context).copyWith(
                                    color: context.textColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  option.subtitle,
                                  style: AppFonts.normal(
                                    context,
                                    size: FontSize.small,
                                  ).copyWith(color: context.textColor),
                                ),
                                value: option.value,
                                activeColor: context.accent,
                                selected: isSelected,
                                selectedTileColor:
                                    context.accent.withValues(alpha: 0.12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                tileColor: Colors.transparent,
                                dense: true,
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _NotificationTimeCard(),
            const SizedBox(height: 16),
            const _ResetReadingProgressCard(),
          ],
        ),
      ),
    );
  }
}

class _NotificationTimeCard extends StatefulWidget {
  const _NotificationTimeCard();

  @override
  State<_NotificationTimeCard> createState() => _NotificationTimeCardState();
}

class _NotificationTimeCardState extends State<_NotificationTimeCard> {
  TimeOfDay _time = NotificationSettings.defaultTime;

  @override
  void initState() {
    super.initState();
    _loadTime();
  }

  Future<void> _loadTime() async {
    final time = await NotificationSettings.getTimeOfDay();
    if (!mounted) return;
    setState(() {
      _time = time;
    });
  }

  Future<void> _pickTime() async {
    if (!mounted) return;
    final picked = await _timePickerFuture();
    if (!mounted || picked == null) return;

    await NotificationSettings.setTimeOfDay(picked);
    if (!mounted) return;

    setState(() {
      _time = picked;
    });

    await NotificationService().initAndScheduleDaily();
  }

  Future<TimeOfDay?> _timePickerFuture() {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS) {
      return _showCupertinoTimePicker(context, _time);
    }
    return showTimePicker(context: context, initialTime: _time);
  }

  Future<TimeOfDay?> _showCupertinoTimePicker(
    BuildContext context,
    TimeOfDay time,
  ) {
    var selected = time;
    final initialDateTime = DateTime(0, 1, 1, time.hour, time.minute);

    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) {
        return Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Done'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                  onDateTimeChanged: (dateTime) {
                    selected = TimeOfDay(
                      hour: dateTime.hour,
                      minute: dateTime.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(_time);

    return Card(
      color: context.backgroundColor.withValues(alpha: 0.8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: context.accent,
                  size: AppIcons.getIconSize(IconSize.medium),
                ),
                const SizedBox(width: 12),
                Text(
                  'Notification Settings',
                  style: AppFonts.bold(context, size: FontSize.large),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              onTap: _pickTime,
              title: Text(
                'Daily reminder time',
                style: AppFonts.normal(context).copyWith(
                  color: context.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Choose when to receive notifications',
                style: AppFonts.normal(
                  context,
                  size: FontSize.small,
                ).copyWith(color: context.textColor),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeLabel, style: AppFonts.bold(context)),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    color: context.textColor.withValues(alpha: 0.7),
                    size: AppIcons.getIconSize(IconSize.small),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: Colors.transparent,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetReadingProgressCard extends StatelessWidget {
  const _ResetReadingProgressCard();

  Future<void> _showResetConfirmation(BuildContext context) async {
    final platform = Theme.of(context).platform;
    bool? shouldReset;

    if (platform == TargetPlatform.iOS) {
      shouldReset = await _showCupertinoResetDialog(context);
    } else {
      shouldReset = await _showMaterialResetDialog(context);
    }

    if (shouldReset != true || !context.mounted) {
      return;
    }

    context.read<ReadingBloc>().add(const ResetReadingProgressEvent());

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reading progress has been reset',
          style: AppFonts.normal(context),
        ),
        backgroundColor: context.backgroundColor.withValues(alpha: 0.8),
      ),
    );
  }

  Future<bool?> _showMaterialResetDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.backgroundColor,
        title: Text(
          'Reset Reading Progress',
          style: AppFonts.bold(context, size: FontSize.large),
        ),
        content: Text(
          "Are you sure you want to wipe Volume I's reading progress?",
          style: AppFonts.normal(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'No, cancel',
              style: AppFonts.normal(context)
                  .copyWith(color: context.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Yes, reset',
              style: AppFonts.normal(context).copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showCupertinoResetDialog(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Reset Reading Progress',
          style: AppFonts.bold(context, size: FontSize.large),
        ),
        content: Text(
          "Are you sure you want to wipe Volume I's reading progress?",
          style: AppFonts.normal(context),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'No, cancel',
              style: AppFonts.normal(context)
                  .copyWith(color: context.textColor),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: Text(
              'Yes, reset',
              style: AppFonts.normal(context).copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.backgroundColor.withValues(alpha: 0.8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.refresh_outlined,
                  color: context.accent,
                  size: AppIcons.getIconSize(IconSize.medium),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reset reading progress',
                  style: AppFonts.bold(context, size: FontSize.large),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Clear all reading progress for Volume I',
                    style: AppFonts.normal(
                      context,
                      size: FontSize.small,
                    ).copyWith(color: context.textColor),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _showResetConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Reset',
                    style: AppFonts.bold(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}