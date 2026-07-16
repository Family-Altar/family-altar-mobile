import 'package:family_altar/models/volume.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/foreword_preface/bloc/foreword_preface_bloc.dart';
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

class ForewordPrefaceScreenProvider extends StatefulWidget {
  const ForewordPrefaceScreenProvider({
    required this.section,
    required this.volume,
    super.key,
  });

  final Section section;
  final Volume volume;

  @override
  State<ForewordPrefaceScreenProvider> createState() =>
      _ForewordPrefaceScreenProviderState();
}

class _ForewordPrefaceScreenProviderState
    extends State<ForewordPrefaceScreenProvider> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => ForewordPrefaceBloc(
            readingRepository: context.read<ReadingRepository>(),
            volume: widget.volume,
          )..add(LoadPageEvent(sect: widget.section)),
      child: ForewordPrefaceScreen(scrollController: _scrollController),
    );
  }
}

class ForewordPrefaceScreen extends StatelessWidget {
  const ForewordPrefaceScreen({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForewordPrefaceBloc, ForewordPrefaceState>(
      listenWhen: (previous, current) {
        if (current is! PageLoaded) return false;
        if (current.section != Section.dailyReading) return false;
        if (previous is! PageLoaded) return true;
        return previous.section != current.section;
      },
      listener: (context, state) {
        if (state is! PageLoaded) return;

        final bloc = context.read<ForewordPrefaceBloc>();
        Utils.getLastAccessedDay(volume: bloc.volume).then((date) {
          if (!context.mounted) return;

          context.push('/reader', extra: date).then((_) {
            if (!context.mounted) return;
            bloc.add(const PreviousPageEvent());
          });
        });
      },
      child: BlocBuilder<ForewordPrefaceBloc, ForewordPrefaceState>(
        builder: (context, state) {
          final title =
              state is PageLoaded ? _sectionTitle(state.section) : 'Reading';
          return SafeArea(
            child: Scaffold(
              backgroundColor: context.backgroundColor,
              appBar: AppBar(
                toolbarHeight: 48,
                backgroundColor: context.backgroundColor,
                centerTitle: true,
                title: Text(title, style: AppFonts.bold(context)),
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
                    onPressed: () => context.go('/'),
                    icon: Icon(
                      Icons.home,
                      color: context.textColor,
                      size: AppIcons.getIconSize(IconSize.medium),
                    ),
                  ),
                  IconButton(
                    onPressed: () => showReadingSettingsBottomSheet(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.textColor,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'A',
                        style: AppFonts.bold(context).copyWith(
                          fontSize: 14,
                          color: context.textColor,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  if (state is! PageLoaded) return;
                  final loadedState = state;
                  if (loadedState.section == Section.dailyReading) return;

                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -500) {
                      if (loadedState.hasNext) {
                        context.read<ForewordPrefaceBloc>().add(
                          const NextPageEvent(),
                        );
                      }
                    } else if (details.primaryVelocity! > 500) {
                      if (loadedState.hasPrevious) {
                        context.read<ForewordPrefaceBloc>().add(
                          const PreviousPageEvent(),
                        );
                      }
                    }
                  }
                },
                child: _ContentBody(
                  state: state,
                  scrollController: scrollController,
                ),
              ),
              bottomNavigationBar: _NavigationBar(
                state: state,
                scrollController: scrollController,
              ),
            ),
          );
        },
      ),
    );
  }

  String _sectionTitle(Section section) {
    switch (section) {
      case Section.foreword:
        return 'Foreword';
      case Section.preface:
        return 'Preface';
      case Section.dailyReading:
        return 'Daily Reading';
    }
  }
}

class _ContentBody extends StatelessWidget {
  const _ContentBody({required this.state, required this.scrollController});

  final ForewordPrefaceState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (state is PageLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PageError) {
      final error = state as PageError;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error.message,
            style: AppFonts.normal(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (state is! PageLoaded) {
      return const SizedBox.shrink();
    }
    final loadedState = state as PageLoaded;
    if (loadedState.section == Section.dailyReading) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final fontSize = themeState.readingFontSize;
        return SingleChildScrollView(
          controller: scrollController,
          child: Scrollbar(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(loadedState.section),
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Text(
                    loadedState.page.text.replaceAll(
                      RegExp(r'(?<!\n)\n(?!\n)'),
                      ' ',
                    ),
                    textAlign: TextAlign.left,
                    style: AppFonts.normal(
                      context,
                    ).copyWith(fontSize: fontSize, height: 1.2),
                    textScaler: TextScaler.noScaling,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({required this.state, required this.scrollController});

  final ForewordPrefaceState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (state is! PageLoaded) return const SizedBox.shrink();
    final loadedState = state as PageLoaded;
    if (loadedState.section == Section.dailyReading) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined),
            iconSize: 50,
            onPressed:
                loadedState.hasPrevious
                    ? () {
                      context.read<ForewordPrefaceBloc>().add(
                        const PreviousPageEvent(),
                      );
                      if (scrollController.hasClients) {
                        scrollController.jumpTo(0);
                      }
                    }
                    : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_circle_right_outlined),
            iconSize: 50,
            onPressed:
                loadedState.hasNext
                    ? () {
                      context.read<ForewordPrefaceBloc>().add(
                        const NextPageEvent(),
                      );
                      if (scrollController.hasClients) {
                        scrollController.jumpTo(0);
                      }
                    }
                    : null,
          ),
        ],
      ),
    );
  }
}
