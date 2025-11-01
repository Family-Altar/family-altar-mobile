import 'package:family_altar/models/reading_entry.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class FamilyAltarCalendar extends StatefulWidget {
  const FamilyAltarCalendar({super.key});

  @override
  State<FamilyAltarCalendar> createState() => _FamilyAltarCalendarState();
}

class _FamilyAltarCalendarState extends State<FamilyAltarCalendar> {
  /// Currently displayed month/year in the calendar
  late DateTime _currentDate;
  
  /// Syncfusion calendar controller for programmatic calendar control
  late CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    // Initialize to first day of current month
    final now = DateTime.now();
    _currentDate = DateTime(now.year, now.month);
    _calendarController = CalendarController();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
  int _getDayOfYear(DateTime date) {
    // Calculate day of year (1-366)
    final firstDayOfYear = DateTime(date.year);
    final difference = date.difference(firstDayOfYear).inDays;
    return difference + 1;
  }

  void _showMarkDialog(
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
          style: AppFonts.bold(context).copyWith(
            color: context.dialogTitle,
          ),
        ),
        content: Text(
          isRead 
              ? 'Do you want to mark this day as unread?'
              : 'Do you want to mark this day as read?',
          style: AppFonts.normal(context).copyWith(
            color: context.dialogContent,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppFonts.normal(context).copyWith(
                color: context.dialogCancel,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (isRead) {
                context.read<ReadingBloc>().add(
                  MarkAsUnreadEvent(date),
                );
              } else {
                context.read<ReadingBloc>().add(
                  MarkAsReadEvent(date),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isRead
                  ? AppColors.dialogMarkUnreadBG
                  : AppColors.dialogMarkReadBG,
            ),
            child: Text(
              isRead ? 'Mark Unread' : 'Mark Read',
              style: AppFonts.normal(context).copyWith(
                color: AppColors.dialogButtonText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(
    ReadingStatus status,
    bool isToday,
    BuildContext context,
  ) {
    if (isToday) {
      return context.calendarTodayBG;
    }
    
    switch (status) {
      case ReadingStatus.completed:
        return context.calendarCompletedBG;
      case ReadingStatus.missed:
        return context.calendarMissedBG;
      case ReadingStatus.upcoming:
        return context.calendarUpcomingBG;
    }
  }

  Color _getStatusBorderColor(
    ReadingStatus status,
    bool isToday,
    BuildContext context,
  ) {
    if (isToday) {
      return AppColors.calendarTodayBorder;
    }
    
    switch (status) {
      case ReadingStatus.completed:
        return AppColors.calendarCompletedBorder;
      case ReadingStatus.missed:
        return AppColors.calendarMissedBorder;
      case ReadingStatus.upcoming:
        return context.calendarUpcomingBorder;
    }
  }

  Widget? _getStatusIcon(ReadingStatus status, bool isToday) {
    if (isToday) return null;
    
    switch (status) {
      case ReadingStatus.completed:
        return const Icon(
          Icons.check,
          size: 12,
          color: AppColors.calendarCompletedIcon,
        );
      case ReadingStatus.missed:
        return const Icon(
          Icons.close,
          size: 12,
          color: AppColors.calendarMissedIcon,
        );
      case ReadingStatus.upcoming:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReadingBloc, ReadingState>(
      builder: (context, state) {
        if (state is ReadingLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is ReadingError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ReadingBloc>().add(const LoadReadingEvent());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
      
        final loadedState = state is ReadingLoaded 
            ? state 
            : null;
        
        // Get total missed days (all time, not just current month)
        final missedDaysCount = loadedState?.getTotalMissedDaysCount() ?? 0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with month navigation and missed days count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month navigation
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentDate = DateTime(
                              _currentDate.year,
                              _currentDate.month - 1,
                            );
                          });
                          _calendarController.displayDate = _currentDate;
                        },
                        icon: Icon(
                          Icons.chevron_left,
                          color: context.calendarMonthText,
                        ),
                      ),
                      Text(
                        _getMonthName(_currentDate.month),
                        style: AppFonts.bold(
                          context,
                          size: FontSize.large,
                        ).copyWith(
                          color: context.calendarMonthText,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentDate = DateTime(
                              _currentDate.year,
                              _currentDate.month + 1,
                            );
                          });
                          _calendarController.displayDate = _currentDate;
                        },
                        icon: Icon(
                          Icons.chevron_right,
                          color: context.calendarMonthText,
                        ),
                      ),
                    ],
                  ),
              // Missed days count - clickable
              GestureDetector(
                onTap: () {
                  // Navigate to books/book-1
                  context.push('/missed-days/book-1');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.missedDaysBadgeBG,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$missedDaysCount missed days',
                        style: AppFonts.normal(
                          context,
                          size: FontSize.small,
                        ).copyWith(
                          color: context.missedDaysBadgeText,
                        ),
                      )
                    ],
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
                headerHeight: 0, // Hide default header
                monthViewSettings: MonthViewSettings(
                  dayFormat: 'E',
                  showTrailingAndLeadingDates: false,
                  appointmentDisplayMode: MonthAppointmentDisplayMode.none,
                  monthCellStyle: MonthCellStyle(
                    textStyle: AppFonts.normal(
                      context,
                      size: FontSize.small,
                    ).copyWith(
                      color: context.calendarDayText,
                      fontWeight: FontWeight.w500,
                    ),
                    trailingDatesTextStyle: AppFonts.normal(
                      context,
                      size: FontSize.small,
                    ).copyWith(
                      color: context.calendarTrailingDate,
                    ),
                    leadingDatesTextStyle: AppFonts.normal(
                      context,
                      size: FontSize.small,
                    ).copyWith(
                      color: context.calendarTrailingDate,
                    ),
                  ),
                ),
                cellBorderColor: context.calendarCellBorder,
                todayHighlightColor: Colors.transparent,
                selectionDecoration: const BoxDecoration(),
                onViewChanged: (ViewChangedDetails details) {
                  if (details.visibleDates.isNotEmpty) {
                    final firstDate = details.visibleDates.first;
                    if (firstDate.month != _currentDate.month ||
                        firstDate.year != _currentDate.year) {
                      setState(() {
                        _currentDate = DateTime(
                          firstDate.year,
                          firstDate.month,
                        );
                      });
                    }
                  }
                },
                onTap: (CalendarTapDetails details) {
                  // Tap to navigate to that day's reading page
                  if (details.date != null) {
                    final dayOfYear = _getDayOfYear(details.date!);
                    context.push('/reader', extra: dayOfYear);
                  }
                },
                onLongPress: (CalendarLongPressDetails details) {
                  if (details.date != null && loadedState != null) {
                    final dayStatus = loadedState.getStatus(details.date!);
                    _showMarkDialog(context, details.date!, dayStatus);
                  }
                },
                monthCellBuilder: (context, details) {
                  final dayStatus = loadedState?.getStatus(details.date) ??
                      ReadingStatus.upcoming;
                  final isToday = _isToday(details.date);

                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(dayStatus, isToday, context),
                      border: Border.all(
                        color: _getStatusBorderColor(
                          dayStatus,
                          isToday,
                          context,
                        ),
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            details.date.day.toString(),
                            style: AppFonts.normal(
                              context,
                              size: FontSize.small,
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: dayStatus == ReadingStatus.upcoming
                                  ? context.calendarUpcomingDayText
                                  : context.calendarDayTextSecondary,
                            ),
                          ),
                        ),
                        if (_getStatusIcon(dayStatus, isToday) != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: _getStatusIcon(dayStatus, isToday)!,
                          ),
                      ],
                    ),
                  );
                },
              ),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(
                    _getStatusColor(ReadingStatus.completed, false, context),
                    'Completed',
                    context,
                  ),
                  _buildLegendItem(
                    _getStatusColor(ReadingStatus.upcoming, true, context),
                    'Today',
                    context,
                  ),
                  _buildLegendItem(
                    _getStatusColor(ReadingStatus.missed, false, context),
                    'Missed',
                    context,
                  ),
                  _buildLegendItem(
                    _getStatusColor(ReadingStatus.upcoming, false, context),
                    'Upcoming',
                    context,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label,
    BuildContext context,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color swatch
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: context.legendBorder,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        // Label text
        Text(
          label,
          style: AppFonts.normal(context, size: FontSize.small).copyWith(
            color: context.legendText,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
