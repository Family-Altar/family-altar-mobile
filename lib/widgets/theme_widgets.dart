import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget to toggle between light and dark themes
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  /// Get the appropriate icon based on current theme state
  IconData _getToggleIcon(ThemeState state) {
    if (state.themeMode == ThemeMode.system) {
      // When system theme is active, show icon for what clicking will switch to
      return state.isDarkMode ? Icons.light_mode : Icons.dark_mode;
    } else if (state.themeMode == ThemeMode.dark) {
      return Icons.light_mode;
    } else {
      return Icons.dark_mode;
    }
  }

  /// Get the appropriate tooltip based on current theme state
  String _getToggleTooltip(ThemeState state) {
    if (state.themeMode == ThemeMode.system) {
      return state.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode';
    } else if (state.themeMode == ThemeMode.dark) {
      return 'Switch to Light Mode';
    } else {
      return 'Switch to Dark Mode';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return IconButton(
          onPressed: () {
            context.read<ThemeBloc>().add(const ThemeToggleEvent());
          },
          icon: Icon(
            _getToggleIcon(state),
          ),
          tooltip: _getToggleTooltip(state),
        );
      },
    );
  }
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Theme Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                RadioGroup<ThemeMode>(
                  groupValue: state.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      context.read<ThemeBloc>().add(
                        ThemeSetEvent(value),
                      );
                    }
                  },
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('Light'),
                        subtitle: Text('Always use light theme'),
                        value: ThemeMode.light,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Dark'),
                        subtitle: Text('Always use dark theme'),
                        value: ThemeMode.dark,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('System'),
                        subtitle: Text('Follow system theme'),
                        value: ThemeMode.system,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
