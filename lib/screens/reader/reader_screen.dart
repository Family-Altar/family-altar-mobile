import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';        // ADD THIS
import 'package:family_altar/theme/bloc/theme_event.dart';      // ADD THIS
import 'package:family_altar/theme/bloc/theme_state.dart';       // ADD THIS
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ReaderScreenProvider extends StatefulWidget {
  const ReaderScreenProvider({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReadingRepository>();

    return BlocProvider(
      create: (_) {
        return ReadingBloc(
          readingRepository: repo,
        )..add(LoadReadingEvent(date: date));
      },
      child: ReaderScreen(
        date: date,
      ),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    this.date,
    super.key,
  });

  final DateTime? date;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        context.read<ReadingBloc>().add(MarkAsReadEvent(widget.date));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReadingBloc, ReadingState>(
      builder: (context, state) {
        if (state is ReadingLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ReadingLoaded) {
          return Scaffold(
            backgroundColor: context.backgroundColor,
            appBar: AppBar(
              toolbarHeight: 48,
              backgroundColor: context.appBarColor,
              centerTitle: true,
              title: Text(state.reading.date, style: AppFonts.bold(context)),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: context.textColor,
                  size: AppIcons.getIconSize(IconSize.medium),
                ),
              ),
               actions: [
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: context.textColor,
                        size: AppIcons.getIconSize(IconSize.medium),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.transparent,
                          isScrollControlled: true,
                          enableDrag: true,
                          useSafeArea: true,
                          builder: (_) => const _SettingsBottomSheet(),
                        );
                      },
                    ),
                  ],
            ),
            body: SingleChildScrollView(
              controller: _scrollController,
              child: Scrollbar(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          textAlign: TextAlign.center,
                          state.reading.scripture.replaceAll('\n', ''),
                       style: AppFonts.italics(context).copyWith(
                                fontSize: themeState.readingFontSize,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          textAlign: TextAlign.left,
                          state.reading.quote.replaceAll('\n', ''),
                         style: AppFonts.normal(context).copyWith(
                                fontSize: themeState.readingFontSize,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        Text(
                          'Daily Reading:',
                          textAlign: TextAlign.center,
                         style: AppFonts.bold(context).copyWith(
                                fontSize: themeState.readingFontSize,
                              ),
                        ),
                        Text(
                          textAlign: TextAlign.left,
                          state.reading.dailyReading,
                             style: AppFonts.bold(context).copyWith(
                                fontSize: themeState.readingFontSize,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.appBarColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_circle_left_outlined),
                        iconSize: 50,
                        onPressed: () {
                          context.read<ReadingBloc>().add(const PreviousReadingEvent());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_circle_right_outlined),
                        iconSize: 50,
                        onPressed: () {
                          context.read<ReadingBloc>().add(const NextReadingEvent());
                        },
                      ),
                    ],
                  ),
                ),
          );
        } else {
          // ReadingInitial or any other unhandled state
          return const SizedBox.shrink();
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ====================== SETTINGS BOTTOM SHEET ======================

class _SettingsBottomSheet extends StatelessWidget {
  const _SettingsBottomSheet();

  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 28.0;
  static const double _fontStep = 1.0;

  static const List<_ThemeOption> _themeOptions = [
    _ThemeOption(title: 'Light', subtitle: 'Always use light theme', value: ThemeMode.light),
    _ThemeOption(title: 'Dark', subtitle: 'Always use dark theme', value: ThemeMode.dark),
    _ThemeOption(title: 'System', subtitle: 'Follow system theme', value: ThemeMode.system),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: context.appBarColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.black.withOpacity(0.2),
          width: 0.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final currentFontSize = themeState.readingFontSize;
          final currentMode = themeState.themeMode;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),

                // Font size controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: currentFontSize > _minFontSize
                            ? () {
                                final newSize = (currentFontSize - _fontStep)
                                    .clamp(_minFontSize, _maxFontSize);
                                context.read<ThemeBloc>().add(
                                  ThemeReadingFontSizeChanged(newSize),
                                );
                              }
                            : null,
                        child: _buildFontButton(
                          context: context,
                          text: 'A',
                          size: 20,
                          circleSize: 56,
                          enabled: currentFontSize > _minFontSize,
                        ),
                      ),
                      Text(
                        '${currentFontSize.round()}',
                        style: AppFonts.normal(context, size: FontSize.large),
                      ),
                      GestureDetector(
                        onTap: currentFontSize < _maxFontSize
                            ? () {
                                final newSize = (currentFontSize + _fontStep)
                                    .clamp(_minFontSize, _maxFontSize);
                                context.read<ThemeBloc>().add(
                                  ThemeReadingFontSizeChanged(newSize),
                                );
                              }
                            : null,
                        child: _buildFontButton(
                          context: context,
                          text: 'A',
                          size: 36,
                          circleSize: 72,
                          enabled: currentFontSize < _maxFontSize,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Theme mode options
                 ..._themeOptions.map((_ThemeOption option) {
                  final isSelected = currentMode == option.value;

                  return RadioListTile<ThemeMode>(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      option.title,
                      style: AppFonts.normal(context).copyWith(
                        color: context.textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      option.subtitle,
                      style: AppFonts.normal(context, size: FontSize.small).copyWith(
                        color: context.textColor,
                      ),
                    ),
                    value: option.value,
                    groupValue: currentMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        context.read<ThemeBloc>().add(ThemeSetEvent(value));
                      }
                    },
                    activeColor: context.accent,
                    selected: isSelected,
                    selectedTileColor: context.accent.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: Colors.transparent,
                    dense: true,
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontButton({
    required BuildContext context,
    required String text,
    required double size,
    required double circleSize,
    required bool enabled,
  }) {
    final color = context.accent;
    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? color.withOpacity(0.12) : Colors.grey.shade200,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: enabled ? color : Colors.grey.shade500,
        ),
      ),
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