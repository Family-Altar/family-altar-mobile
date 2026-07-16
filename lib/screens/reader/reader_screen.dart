import 'package:drop_cap_text/drop_cap_text.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
import 'package:family_altar/utils/utilities.dart';
import 'package:family_altar/widgets/reading_settings_bottom_sheet.dart';
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

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  late final ScrollController _scrollController;
  double _horizontalDragDistance = 0;
  double _verticalDragDistance = 0;
  bool _isHorizontalSwipe = false;
  bool _contentFitsWithoutScroll = false;
  late DateTime _currentDate = widget.date;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScrollEnd);
    WidgetsBinding.instance.addObserver(this);
  }

  void _onScrollEnd() {
    // Below the negligible-scroll threshold, only the manual button marks
    // as read.
    if (_contentFitsWithoutScroll) return;
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<ReadingBloc>().add(MarkAsReadEvent(_currentDate));
    }
  }

  // Catches content-size changes (e.g. font-size setting) that
  // ScrollController listeners miss.
  void _scheduleScrollCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollNeeded());
  }

  // Below this, remaining scroll distance is too small to reliably land
  // on maxScrollExtent.
  static const double _negligibleScrollExtent = 150;

  void _checkScrollNeeded() {
    if (!mounted || !_scrollController.hasClients) return;
    final fitsWithoutScroll =
        _scrollController.position.maxScrollExtent <= _negligibleScrollExtent;
    if (fitsWithoutScroll != _contentFitsWithoutScroll) {
      setState(() => _contentFitsWithoutScroll = fitsWithoutScroll);
    }
  }

  @override
  void didChangeMetrics() {
    _scheduleScrollCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_onScrollEnd)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          _currentDate = state.currentDate;
          _scheduleScrollCheck();
        }
      },
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

            return SafeArea(
              child: Scaffold(
                backgroundColor: context.backgroundColor,
                appBar: AppBar(
                  toolbarHeight: 48,
                  backgroundColor: context.backgroundColor,
                  centerTitle: true,
                  title: Text(
                    state.reading.date,
                    style: AppFonts.bold(context),
                  ),
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
                      onPressed: () => context.go('/'),
                      icon: Icon(
                        Icons.home,
                        color: context.textColor,
                        size: AppIcons.getIconSize(IconSize.medium),
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: context.backgroundColor,
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: context.backgroundColor,
                          child: Icon(
                            Icons.more_horiz,
                            color: context.textColor,
                            size: 20,
                          ),
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'share') {
                          final reading = state.reading;
                          final fullShareText = formatReadingForSharing(
                            reading,
                          );
                          SharePlus.instance.share(
                            ShareParams(text: fullShareText.trim()),
                          );
                        } else if (value == 'settings') {
                          showReadingSettingsBottomSheet(context);
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.share,
                                    color: context.textColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Share Reading',
                                    style: AppFonts.normal(context),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: context.textColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Font and Settings',
                                    style: AppFonts.normal(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                body: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    _horizontalDragDistance = 0.0;
                    _verticalDragDistance = 0.0;
                    _isHorizontalSwipe = false;
                  },
                  onPanUpdate: (details) {
                    _horizontalDragDistance += details.delta.dx;
                    _verticalDragDistance += details.delta.dy.abs();
                    if (_horizontalDragDistance.abs() + _verticalDragDistance >
                        20) {
                      _isHorizontalSwipe =
                          _horizontalDragDistance.abs() >
                          _verticalDragDistance * 1.5;
                    }
                  },
                  onPanEnd: (details) {
                    if (_isHorizontalSwipe) {
                      final horizontalAbs = _horizontalDragDistance.abs();
                      final velocity = details.velocity.pixelsPerSecond.dx;
                      if (horizontalAbs > 80 || velocity.abs() > 400) {
                        if (_horizontalDragDistance < 0 || velocity < 0) {
                          context.read<ReadingBloc>().add(
                            const NextReadingEvent(),
                          );
                        } else {
                          context.read<ReadingBloc>().add(
                            const PreviousReadingEvent(),
                          );
                        }
                      }
                    }
                    _horizontalDragDistance = 0.0;
                    _verticalDragDistance = 0.0;
                    _isHorizontalSwipe = false;
                  },
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (notification) {
                      _scheduleScrollCheck();
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Scrollbar(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                Center(
                                  child: Image.asset(
                                    'assets/icon/divider.png',
                                    color:
                                        context.isDarkMode
                                            ? Colors.white
                                            : null,
                                    width: (fontSize * 20).clamp(0, 400),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                DropCapText(
                                  dropCapStyle: TextStyle(
                                    fontFamily: 'OldEnglish',
                                    fontSize: 50,
                                    color:
                                        context.isDarkMode
                                            ? Colors.white
                                            : null,
                                  ),
                                  state.reading.quote,
                                  textAlign: TextAlign.left,
                                  style: AppFonts.normal(
                                    context,
                                  ).copyWith(fontSize: fontSize, height: 1.2),
                                  dropCapPadding: const EdgeInsets.only(
                                    right: 8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.reading.title,
                                  textAlign: TextAlign.left,
                                  style: AppFonts.italics(
                                    context,
                                  ).copyWith(fontSize: fontSize),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Image.asset(
                                    'assets/icon/divider.png',
                                    color:
                                        context.isDarkMode
                                            ? Colors.white
                                            : null,
                                    width: (fontSize * 20).clamp(0, 400),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Daily Reading: '
                                  '${state.reading.dailyReading}',
                                  textAlign: TextAlign.left,
                                  style: AppFonts.normal(
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
                ),
                bottomNavigationBar: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    border: const Border(
                      top: BorderSide(color: Color.fromARGB(58, 137, 136, 136)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        color: context.textColor,
                        icon: const Icon(Icons.arrow_circle_left_outlined),
                        iconSize: 40,
                        onPressed:
                            () => {
                              _scrollController.jumpTo(0),
                              context.read<ReadingBloc>().add(
                                const PreviousReadingEvent(),
                              ),
                            },
                      ),
                      if (_contentFitsWithoutScroll &&
                          !state.isCurrentDayRead())
                        FilledButton.icon(
                          onPressed:
                              () => context.read<ReadingBloc>().add(
                                MarkAsReadEvent(_currentDate),
                              ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.dialogMarkReadBG,
                          ),
                          icon: const Icon(
                            Icons.check,
                            color: AppColors.dialogButtonText,
                            size: 18,
                          ),
                          label: const Text(
                            'Mark as Read',
                            style: TextStyle(color: AppColors.dialogButtonText),
                          ),
                        ),
                      IconButton(
                        color: context.textColor,
                        icon: const Icon(Icons.arrow_circle_right_outlined),
                        iconSize: 40,
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
              ),
            );
          },
        );
      },
    );
  }
}
