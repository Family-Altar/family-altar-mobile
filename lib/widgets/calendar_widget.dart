import 'package:family_altar/models/reading_entry.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class FamilyAltarCalendar extends StatefulWidget {
  const FamilyAltarCalendar({super.key});

  @override
  State<FamilyAltarCalendar> createState() => _FamilyAltarCalendarState();
}

class _FamilyAltarCalendarState extends State<FamilyAltarCalendar> {
  late DateTime _currentDate;
  late CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime(DateTime.now().year, DateTime.now().month);
    _calendarController = CalendarController();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  void _showLongPressDialog(
    BuildContext context,
    DateTime date,
    ReadingStatus status,
  ) {
    final isRead = status == ReadingStatus.completed;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.dialogBG,
        title: Text(
          isRead ? 'Mark as Unread' : 'Mark as Read',
          style: AppFonts.bold(context)
              .copyWith(color: context.dialogTitle),
        ),
        content: Text(
          isRead
              ? 'Do you want to mark this day as unread?'
              : 'Do you want to mark this day as read?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.dialogCancel),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ReadingBloc>().add(
                    isRead
                        ? MarkAsUnreadEvent(date)
                        : MarkAsReadEvent(date),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isRead
                  ? AppColors.dialogMarkUnreadBG
                  : AppColors.dialogMarkReadBG,
            ),
            child: Text(
              isRead ? 'Mark Unread' : 'Mark Read',
              style: const TextStyle(color: AppColors.dialogButtonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onPressed,
        icon: Icon(icon, size: 28, color: context.calendarMonthText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReadingBloc, ReadingState>(
      builder: (context, state) {
        final loadedState = state is ReadingLoaded ? state : null;
        final missedDaysCount =
            loadedState?.getTotalMissedDaysCount() ?? 0;
        final headerDate =
            DateFormat('MMM yyyy').format(_currentDate);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  _navButton(Icons.chevron_left, () {
                    setState(() {
                      _currentDate = DateTime(
                        _currentDate.year,
                        _currentDate.month - 1,
                      );
                      _calendarController.displayDate = _currentDate;
                    });
                  }),
                  const SizedBox(width: 12),
                  Text(
                    headerDate,
                    style: AppFonts.bold(context, size: FontSize.large)
                        .copyWith(color: context.calendarMonthText),
                  ),
                  const SizedBox(width: 12),
                  _navButton(Icons.chevron_right, () {
                    setState(() {
                      _currentDate = DateTime(
                        _currentDate.year,
                        _currentDate.month + 1,
                      );
                      _calendarController.displayDate = _currentDate;
                    });
                  }),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/missed-days/book-1'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.missedDaysBadgeBG,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$missedDaysCount missed',
                        style: AppFonts.normal(
                          context,
                          size: FontSize.small,
                        ).copyWith(color: context.missedDaysBadgeText),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calendar
              SfCalendar(
                controller: _calendarController,
                view: CalendarView.month,
                initialDisplayDate: _currentDate,
                headerHeight: 0,
                monthViewSettings: const MonthViewSettings(
                  dayFormat: 'E',
                  showTrailingAndLeadingDates: false,
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.none,
                ),
                cellBorderColor: Colors.transparent,
                todayHighlightColor: context.calendarTodayBorder,
                selectionDecoration: const BoxDecoration(),
                onViewChanged: (details) {
                  if (details.visibleDates.isEmpty) return;
                  final first = details.visibleDates.first;
                  if (first.month != _currentDate.month ||
                      first.year != _currentDate.year) {
                    setState(() {
                      _currentDate =
                          DateTime(first.year, first.month);
                    });
                  }
                },
                onTap: (details) {
                  if (details.date != null) {
                    context.push('/reader', extra: details.date);
                  }
                },
                onLongPress: (details) {
                  if (details.date == null || loadedState == null) {
                    return;
                  }
                  final status = loadedState.getStatus(details.date!);
                  _showLongPressDialog(context, details.date!, status);
                },
                monthCellBuilder: (context, details) {
                  final date = details.date;
                  final status = loadedState?.getStatus(date) ??
                      ReadingStatus.upcoming;

                  final isToday = DateTime.now().year == date.year &&
                      DateTime.now().month == date.month &&
                      DateTime.now().day == date.day;

                  final borderColor = isToday
                      ? context.calendarTodayBorder
                          .withValues(alpha: 0.7)
                      : status == ReadingStatus.completed
                          ? context.calendarCompletedBorder
                              .withValues(alpha: 0.3)
                          : status == ReadingStatus.missed
                              ? context.calendarMissedBorder
                                  .withValues(alpha: 0.3)
                              : context.calendarUpcomingBorder
                                  .withValues(alpha: 0.3);

                  Widget? statusIcon;
                  if (status == ReadingStatus.completed) {
                    statusIcon = Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: context.calendarCompletedIcon
                            .withValues(alpha: 0.9),
                      ),
                    );
                  } else if (status == ReadingStatus.missed) {
                    statusIcon = Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: context.calendarMissedIcon
                            .withValues(alpha: 0.4),
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: isToday ? 2.5 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            date.day.toString(),
                            style: AppFonts.normal(
                              context,
                              size: FontSize.small,
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: status == ReadingStatus.upcoming
                                  ? context.calendarUpcomingDayText
                                  : context.calendarDayTextSecondary,
                            ),
                          ),
                        ),
                        if (statusIcon != null) statusIcon,
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}