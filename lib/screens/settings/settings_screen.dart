import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: context.appBarColor,
        title: Text(
          'Settings',
          style: AppFonts.bold(context),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          color: Theme.of(context).colorScheme.primary,
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
                        return Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              title: Text(
                                'Light',
                                style: AppFonts.normal(context),
                              ),
                              subtitle: Text(
                                'Always use light theme',
                                style: AppFonts.normal(
                                  context,
                                  size: FontSize.small,
                                ),
                              ),
                              value: ThemeMode.light,
                              groupValue: state.themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  context.read<ThemeBloc>().add(
                                    ThemeSetEvent(value),
                                  );
                                }
                              },
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text(
                                'Dark',
                                style: AppFonts.normal(context),
                              ),
                              subtitle: Text(
                                'Always use dark theme',
                                style: AppFonts.normal(
                                  context,
                                  size: FontSize.small,
                                ),
                              ),
                              value: ThemeMode.dark,
                              groupValue: state.themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  context.read<ThemeBloc>().add(
                                    ThemeSetEvent(value),
                                  );
                                }
                              },
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text(
                                'System',
                                style: AppFonts.normal(context),
                              ),
                              subtitle: Text(
                                'Follow system theme',
                                style: AppFonts.normal(
                                  context,
                                  size: FontSize.small,
                                ),
                              ),
                              value: ThemeMode.system,
                              groupValue: state.themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  context.read<ThemeBloc>().add(
                                    ThemeSetEvent(value),
                                  );
                                }
                              },
                            ),
                          ],
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
