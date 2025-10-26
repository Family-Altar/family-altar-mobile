import 'package:family_altar/screens/reading/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DayReadingScreen extends StatefulWidget {
  const DayReadingScreen({
    required this.dayId,
    super.key,
  });

  final String dayId;

  @override
  State<DayReadingScreen> createState() => _DayReadingScreenState();
}

class _DayReadingScreenState extends State<DayReadingScreen> {
  @override
  void initState() {
    super.initState();
    _saveLastAccessedDay();
  }

  DateTime _getDayOfYearAsDate(int dayOfYear) {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year);
    return firstDayOfYear.add(Duration(days: dayOfYear - 1));
  }

  void _saveLastAccessedDay() {
    try {
      final dayNumber = int.parse(widget.dayId.replaceAll('day-', ''));
      final date = _getDayOfYearAsDate(dayNumber);
      ReadingBloc.saveLastAccessedDay(date);
    } on FormatException {
      // Invalid day ID format, ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarColor,
        title: Text(
          'Day ${widget.dayId} Reading',
          style: AppFonts.bold(context),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Day ${widget.dayId} Reading - todo',
                style: AppFonts.bold(context, size: FontSize.large),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}

