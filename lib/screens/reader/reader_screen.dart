import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ReaderScreenProvider extends StatelessWidget {
  const ReaderScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReadingRepository>();

    return BlocProvider(
      create: (_) {
        final bloc = ReadingBloc(readingRepository: repo);
        bloc.add(const LoadReadingEvent());
        return bloc;
      },
      child: const ReaderScreen(),
    );
  }
}

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: context.appBarColor,
        title: Text('test', style: AppFonts.bold(context)),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
            size: AppIcons.getIconSize(IconSize.medium),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: BlocBuilder<ReadingBloc, ReadingState>(
          builder: (context, state) {
            if (state is ReadingLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ReadingLoaded) {
              return Scrollbar(
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        state.reading.scripture,
                        style: AppFonts.italics(context),
                      ),
                      Text(
                        state.reading.quote,
                        style: AppFonts.normal(context),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // ReadingInitial or any other unhandled state
              return const SizedBox.shrink();
            }
          },
        ),
      ),
      bottomNavigationBar: Container(
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
              onPressed: () {
                print("button pressed");
                // TODO: navigate to previous day
              },
            ),
            const Text(
              'Day 8 of 366',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_circle_right_outlined),
              onPressed: () {
                // TODO: navigate to next day
              },
            ),
          ],
        ),
      ),
    );
  }
}
