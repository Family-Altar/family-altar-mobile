import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showReadingSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ReadingSettingsBottomSheet(),
  );
}


class ReadingSettingsBottomSheet extends StatelessWidget {
  const ReadingSettingsBottomSheet({super.key});

  static const _options = [
    _ThemeOption(
      title: 'Light',
      subtitle: 'Always use light theme',
      value: ThemeMode.light,
    ),
    _ThemeOption(
      title: 'Dark',
      subtitle: 'Always use dark theme',
      value: ThemeMode.dark,
    ),
    _ThemeOption(
      title: 'System',
      subtitle: 'Follow system theme',
      value: ThemeMode.system,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.5,
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color:
              dark
                  ? Colors.grey.shade700
                  : context.accent.withValues(alpha: 0.2),
          width: 0.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final mode = themeState.themeMode;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                const _FontSizeControl(),
                const SizedBox(height: 24),
                RadioGroup<ThemeMode>(
                  groupValue: mode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ThemeBloc>().add(ThemeSetEvent(value));
                    }
                  },
                  child: Column(
                    children:
                        _options.map((o) {
                          final isSelected = mode == o.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap:
                                  () => context.read<ThemeBloc>().add(
                                    ThemeSetEvent(o.value),
                                  ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? context.accent.withValues(
                                            alpha: 0.05,
                                          )
                                          : null,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Radio<ThemeMode>(
                                      value: o.value,
                                      activeColor: context.accent,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            o.title,
                                            style: AppFonts.normal(
                                              context,
                                            ).copyWith(
                                              color: context.textColor,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          Text(
                                            o.subtitle,
                                            style: AppFonts.normal(
                                              context,
                                              size: FontSize.small,
                                            ).copyWith(
                                              color: context.textColor
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  const _FontSizeControl();

  static const double _min = 12;
  static const double _max = 28;
  static const int _step = 1;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final current = themeState.readingFontSize;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTapDown: (details) {
              final width = context.size?.width ?? 300;
              final x = details.localPosition.dx;

              final nextValue =
                  x < width / 2 ? current - _step : current + _step;

              final newSize = nextValue.clamp(_min, _max);

              if (newSize != current) {
                context.read<ThemeBloc>().add(
                  ThemeReadingFontSizeChanged(newSize),
                );
              }
            },
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: context.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: current > _min ? 1.0 : 0.4,
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    color: context.accent.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: Opacity(
                      opacity: current < _max ? 1.0 : 0.4,
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: context.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption {
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final ThemeMode value;
}
