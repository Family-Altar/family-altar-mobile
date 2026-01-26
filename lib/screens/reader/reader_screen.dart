import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class ReaderScreenProvider extends StatefulWidget {
  const ReaderScreenProvider({required this.date, super.key});
  final DateTime date;

  @override
  State<ReaderScreenProvider> createState() => _ReaderScreenProviderState();
}

class _ReaderScreenProviderState extends State<ReaderScreenProvider> {
  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(LoadReadingEvent(date: widget.date));
  }

  @override
  Widget build(BuildContext context) => ReaderScreen(date: widget.date);
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({required this.date, super.key});
  final DateTime date;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScrollEnd);
  }

  void _onScrollEnd() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<ReadingBloc>().add(MarkAsReadEvent(widget.date));
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScrollEnd)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReadingBloc, ReadingState>(
      builder: (context, state) {
        if (state is ReadingLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is! ReadingLoaded) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final fontSize = themeState.readingFontSize;

            return Scaffold(
              backgroundColor: context.backgroundColor,
              appBar: AppBar(
                toolbarHeight: 48,
                backgroundColor: context.appBarColor,
                centerTitle: true,
                title: Text(state.reading.date, style: AppFonts.bold(context)),
                leading: IconButton(
                  onPressed: context.pop,
                  icon: Icon(
                    Icons.arrow_back,
                    color: context.textColor,
                    size: AppIcons.getIconSize(IconSize.medium),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: context.textColor,
                      size: AppIcons.getIconSize(IconSize.medium),
                    ),
                    onPressed: () async {
                      final reading = state.reading;

                      final shareContent =
                          '''
                ${reading.scripture.replaceAll('\n', '')}

                ${reading.quote.replaceAll('\n', '')}

                Daily Reading:
                ${reading.dailyReading}
                '''.trimLeft();

                      final fullShareText =
                          '''
                Family Altar Reading
                ${reading.date}

                $shareContent
                '''.trimLeft();

                      await Share.share(fullShareText);
                    },
                  ),

                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: context.textColor,
                      size: AppIcons.getIconSize(IconSize.medium),
                    ),
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        barrierColor: Colors.transparent,
                        isScrollControlled: true,
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
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(state.reading.date),
                        duration: const Duration(milliseconds: 200),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(opacity: value, child: child);
                        },
                        child: Column(
                          children: [
                            Text(
                              state.reading.scripture.replaceAll('\n', ' '),
                              textAlign: TextAlign.center,
                              style: AppFonts.italics(
                                context,
                              ).copyWith(fontSize: fontSize),
                              textScaler: TextScaler.noScaling,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.reading.quote.replaceAll('\n', ' '),
                              textAlign: TextAlign.left,
                              style: AppFonts.normal(
                                context,
                              ).copyWith(fontSize: fontSize),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.reading.title,
                              textAlign: TextAlign.left,
                              style: AppFonts.normal(
                                context,
                              ).copyWith(fontSize: fontSize),
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            Text(
                              'Daily Reading:',
                              textAlign: TextAlign.center,
                              style: AppFonts.bold(
                                context,
                              ).copyWith(fontSize: fontSize),
                            ),
                            Text(
                              state.reading.dailyReading,
                              textAlign: TextAlign.left,
                              style: AppFonts.bold(
                                context,
                              ).copyWith(fontSize: fontSize),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.appBarColor,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      color: context.textColor,
                      icon: const Icon(Icons.arrow_circle_left_outlined),
                      iconSize: 50,
                      onPressed:
                          () => {
                            _scrollController.jumpTo(0),
                            context.read<ReadingBloc>().add(
                              const PreviousReadingEvent(),
                            ),
                          },
                    ),
                    IconButton(
                      color: context.textColor,
                      icon: const Icon(Icons.arrow_circle_right_outlined),
                      iconSize: 50,
                      onPressed:
                          () => {
                            context.read<ReadingBloc>().add(
                              const NextReadingEvent(),
                            ),
                            _scrollController.jumpTo(0),
                          },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

class _SettingsBottomSheet extends StatelessWidget {
  const _SettingsBottomSheet();

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
        color: context.appBarColor,
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
