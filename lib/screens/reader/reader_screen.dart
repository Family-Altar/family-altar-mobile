import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ReaderScreenProvider extends StatelessWidget {
  const ReaderScreenProvider({
    required this.date,
    super.key,
  });

  // from calendar widget or from continue reading button
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        print('Mark as read $_scrollController.offset');
      }
    });
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
                          style: AppFonts.italics(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          textAlign: TextAlign.left,
                          state.reading.quote.replaceAll('\n', ''),
                          style: AppFonts.normal(context),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        Text(
                          'Daily Reading:',
                          textAlign: TextAlign.center,
                          style: AppFonts.bold(context),
                        ),
                        Text(
                          textAlign: TextAlign.left,
                          state.reading.dailyReading,
                          style: AppFonts.bold(context),
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
                color: context.backgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_circle_left_outlined),
                    iconSize: 50,
                    onPressed: () {
                      context.read<ReadingBloc>().add(
                        const PreviousReadingEvent(),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_circle_right_outlined),
                    iconSize: 50,
                    onPressed: () {
                      context.read<ReadingBloc>().add(
                        const NextReadingEvent(),
                      );
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
      },
    );
  }
}
