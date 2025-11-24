import 'package:family_altar/noti_service.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
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
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    NotiService().showNotification(
                      title: 'title',
                      body: 'read now',
                    );
                  },
                  child: const Text('hi'),
                ),
                ElevatedButton(
                  onPressed: () {
                    NotiService().scheduleNotification(
                      title: 'title',
                      body: 'read now',
                      hour: 22,
                      minute: 50,
                    );
                  },
                  child: const Text('schedule'),
                ),
              ],
            ),
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
                            children:
                                themeOptions.map((option) {
                                  final isSelected =
                                      currentMode == option.value;

                                  return RadioListTile<ThemeMode>.adaptive(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    title: Text(
                                      option.title,
                                      style: AppFonts.normal(context).copyWith(
                                        color: context.textColor,
                                        fontWeight:
                                            isSelected
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
                                    selectedTileColor: context.accent
                                        .withValues(alpha: 0.12),
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
          ],
        ),
      ),
    );
  }
}
