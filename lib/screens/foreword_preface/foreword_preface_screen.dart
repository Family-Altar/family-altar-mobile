import 'dart:async';

import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/foreword_preface/bloc/foreword_preface_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:family_altar/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ForewordPrefaceScreenProvider extends StatelessWidget {
  const ForewordPrefaceScreenProvider({required this.section, super.key});

  final Section section;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => ForewordPrefaceBloc(
            readingRepository: context.read<ReadingRepository>(),
          )..add(LoadPageEvent(sect: section)),
      child: const ForewordPrefaceScreen(),
    );
  }
}

class ForewordPrefaceScreen extends StatelessWidget {
  const ForewordPrefaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForewordPrefaceBloc, ForewordPrefaceState>(
      listenWhen: (previous, current) {
        if (current is! PageLoaded) return false;
        if (current.section != Section.dailyReading) return false;
        if (previous is! PageLoaded) return true;
        return previous.section != current.section;
      },
      listener: (context, state) async {
        if (state is! PageLoaded) return;
        final date = await Utils.getLastAccessedDay();
        final bloc = context.read<ForewordPrefaceBloc>();
        unawaited(
          context.push('/reader', extra: date).then((_) {
            bloc.add(const PreviousPageEvent());
          }),
        );
      },
      child: BlocBuilder<ForewordPrefaceBloc, ForewordPrefaceState>(
        builder: (context, state) {
          final title =
              state is PageLoaded ? _sectionTitle(state.section) : 'Reading';
          return Scaffold(
            backgroundColor: context.backgroundColor,
            appBar: AppBar(
              toolbarHeight: 48,
              backgroundColor: context.appBarColor,
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
            ),
            body: _ContentBody(state: state),
            bottomNavigationBar: _NavigationBar(state: state),
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
  const _ContentBody({required this.state});

  final ForewordPrefaceState state;

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
    return SingleChildScrollView(
      child: Scrollbar(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loadedState.page.text.replaceAll(RegExp(r'(?<!\n)\n(?!\n)'), ' '),
              textAlign: TextAlign.left,
              style: AppFonts.normal(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({required this.state});

  final ForewordPrefaceState state;

  @override
  Widget build(BuildContext context) {
    if (state is! PageLoaded) return const SizedBox.shrink();
    final loadedState = state as PageLoaded;
    if (loadedState.section == Section.dailyReading) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    ? () => context.read<ForewordPrefaceBloc>().add(
                      const PreviousPageEvent(),
                    )
                    : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_circle_right_outlined),
            iconSize: 50,
            onPressed:
                loadedState.hasNext
                    ? () => context.read<ForewordPrefaceBloc>().add(
                      const NextPageEvent(),
                    )
                    : null,
          ),
        ],
      ),
    );
  }
}
