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

class _FamilyAltarCalendarState extends State<FamilyAltarCalendar>
    with SingleTickerProviderStateMixin {
  late DateTime _currentDate;
  late CalendarController _calendarController;
  late AnimationController _alertController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime(DateTime.now().year, DateTime.now().month);
    _calendarController = CalendarController();

    // Setup a pulsing animation for the "Missed Days" alert
    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _alertController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  // --- Logic Helpers ---

  static int _daysInYear(int year) {
    final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 366 : 365;
  }

  int _weeksInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month);
    final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
    // SfCalendar month view is configured with Sunday as the first column.
    final leadingDays = firstDay.weekday % DateTime.daysPerWeek;
    return ((leadingDays + daysInMonth) / DateTime.daysPerWeek).ceil();
  }

  // Keep 5 rows visible by default. If month needs a 6th row, add just one

  double _calendarHeightForMonth({required bool isLandscape}) {
    final weekRows = _weeksInMonth(_currentDate);
    final extraRowCount = (weekRows - 5).clamp(0, 1);
    final baseHeight = isLandscape ? 270.0 : 320.0;
    final extraRowHeight = isLandscape ? 40.0 : 46.0;
    return baseHeight + (extraRowCount * extraRowHeight);
  }

  String _calculateCompletionPercentage(ReadingLoaded? loadedState) {
    if (loadedState == null) return '0';

    // Completed count only (excludes missed).
    // Denominator = days in current year.
    final completedCount = loadedState.getTotalCompletedDaysCount();
    final daysInYear = _daysInYear(DateTime.now().year);
    final percentage = (completedCount / daysInYear) * 100;

    return percentage.clamp(0.0, 100.0).toStringAsFixed(0);
  }

  void _onCalendarViewChanged(ViewChangedDetails details) {
    if (details.visibleDates.isEmpty) return;
    final midIndex = details.visibleDates.length ~/ 2;
    final middleDate = details.visibleDates[midIndex];

    if (middleDate.month != _currentDate.month ||
        middleDate.year != _currentDate.year) {
      setState(() {
        _currentDate = DateTime(middleDate.year, middleDate.month);
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + offset);
      _calendarController.displayDate = _currentDate;
    });
  }

  void _goToToday() {
    setState(() {
      _currentDate = DateTime(DateTime.now().year, DateTime.now().month);
      _calendarController.displayDate = _currentDate;
    });
  }

  // --- UI Builders ---

  Widget _buildHeader(BuildContext context) {
    final headerDate = DateFormat('MMMM yyyy').format(_currentDate);
    final navStyle = IconButton.styleFrom(
      foregroundColor: context.calendarMonthText,
    );
    // Same width on both sides so the month label stays visually centered.
    const sideSlotWidth = 112.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: sideSlotWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    style: navStyle,
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    style: navStyle,
                    onPressed: _goToToday,
                    icon: const Icon(Icons.today),
                    tooltip: 'Today',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Text(
              headerDate,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.bold(
                context,
                size: FontSize.small,
              ).copyWith(color: context.calendarMonthText, letterSpacing: 0.5),
            ),
          ),
          SizedBox(
            width: sideSlotWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                style: navStyle,
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedBadge(BuildContext context, int missedCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (missedCount > 0)
            Icon(Icons.circle, size: 8, color: Colors.red.shade400),
          const SizedBox(width: 2),
          Text(
            '  $missedCount Missed ',
            style: AppFonts.normal(
              context,
              size: FontSize.small,
            ).copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          if (missedCount > 0)
            Icon(Icons.arrow_forward, size: 16, color: Colors.red.shade400),
        ],
      ),
    );
  }

  Widget _buildStatsBar(
    BuildContext context,
    String percentage,
    int missedCount,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.check, size: 18, color: Colors.green.shade400),
          const SizedBox(width: 8),
          Text(
            '$percentage% Completed',
            style: AppFonts.normal(context, size: FontSize.small).copyWith(
              fontWeight: FontWeight.w600,
              color: context.calendarDayTextSecondary,
            ),
          ),
          const Spacer(),
          // Missed Stat (always visible and tappable)
          InkWell(
            onTap: () => context.push('/missed-days/book-1'),
            borderRadius: BorderRadius.circular(20),
            child:
                missedCount > 0
                    ? ScaleTransition(
                      scale: _pulseAnimation,
                      child: _buildMissedBadge(context, missedCount),
                    )
                    : _buildMissedBadge(context, missedCount),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReadingBloc, ReadingState>(
      builder: (context, state) {
        final loadedState = state is ReadingLoaded ? state : null;
        final missedDaysCount = loadedState?.getTotalMissedDaysCount() ?? 0;
        final completionPercentage = _calculateCompletionPercentage(
          loadedState,
        );

        // Avoid constantly ticking animation when there are no missed days.
        if (missedDaysCount > 0) {
          if (!_alertController.isAnimating) {
            _alertController.repeat(reverse: true);
          }
        } else if (_alertController.isAnimating) {
          _alertController
            ..stop()
            ..value = 1;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final mediaQuery = MediaQuery.of(context);
            final isLandscape =
                mediaQuery.orientation == Orientation.landscape;
            const calendarMaxWidth = 680.0;
            final compact = constraints.maxHeight < 360;
            final bottomPadding =
                (compact ? 8.0 : 24.0) +
                mediaQuery.padding.bottom +
                (isLandscape ? 16.0 : 0.0);
            final sidePadding = compact ? 12.0 : 16.0;

            final calendarCard = Container(
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(6),
              child: SfCalendar(
                controller: _calendarController,
                view: CalendarView.month,
                // Let parent scroll view handle drag gestures on
                // small landscape screens.
                initialDisplayDate: _currentDate,
                headerHeight: 0,
                backgroundColor: Colors.transparent,
                monthViewSettings: const MonthViewSettings(
                  dayFormat: 'EEE',
                  showTrailingAndLeadingDates: false,
                  appointmentDisplayMode: MonthAppointmentDisplayMode.none,
                ),
                cellBorderColor: Colors.transparent,
                selectionDecoration: const BoxDecoration(),
                onViewChanged: _onCalendarViewChanged,
                onTap: (details) {
                  if (details.date != null) {
                    context.push('/reader', extra: details.date);
                  }
                },
                monthCellBuilder: (context, details) {
                  final cellDate = details.date;
                  final cellStatus =
                      loadedState?.getStatus(cellDate) ??
                      ReadingStatus.upcoming;
                  return GestureDetector(
                    onLongPress: loadedState != null
                        ? () => _showLongPressDialog(
                              context,
                              cellDate,
                              cellStatus,
                            )
                        : null,
                    child: _CalendarCell(
                      date: cellDate,
                      status: cellStatus,
                    ),
                  );
                },
              ),
            );

            final topSection = <Widget>[
              _buildStatsBar(context, completionPercentage, missedDaysCount),
              _buildHeader(context),
            ];

            final calendarHeight = _calendarHeightForMonth(
              isLandscape: isLandscape,
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                sidePadding,
                8,
                sidePadding,
                bottomPadding,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...topSection,
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: calendarMaxWidth,
                        ),
                        child: SizedBox(
                          height: calendarHeight,
                          child: calendarCard,
                        ),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 40 : 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLongPressDialog(
    BuildContext context,
    DateTime date,
    ReadingStatus status,
  ) {
    final isRead = status == ReadingStatus.completed;
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: context.dialogBG,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              isRead ? 'Mark as Unread' : 'Mark as Read',
              style: AppFonts.bold(
                context,
              ).copyWith(color: context.dialogTitle),
            ),
            content: Text(
              isRead
                  ? 'Do you want to mark this day as unread?'
                  : 'Do you want to mark this day as read?',
              style: AppFonts.normal(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: context.dialogCancel),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<ReadingBloc>().add(
                    isRead ? MarkAsUnreadEvent(date) : MarkAsReadEvent(date),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isRead
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
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({required this.date, required this.status});
  final DateTime date;
  final ReadingStatus status;

  @override
  Widget build(BuildContext context) {
    final isToday =
        DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    Color borderColor;
    Color? fillColor;

    borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.2);

    if (isToday) {
      borderColor = context.calendarTodayBorder;
      fillColor = context.calendarTodayBorder.withValues(alpha: 0.1);
    } else {
      switch (status) {
        case ReadingStatus.completed:
          borderColor = context.calendarCompletedBorder.withValues(alpha: 0.5);
          fillColor = context.calendarCompletedBorder.withValues(alpha: 0.05);

        case ReadingStatus.missed:
          borderColor = context.calendarMissedBorder.withValues(alpha: 0.5);
          fillColor = context.calendarMissedBorder.withValues(alpha: 0.05);

        case ReadingStatus.upcoming:
          fillColor = Colors.transparent;
      }
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: isToday ? 2.0 : 1.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              date.day.toString(),
              style: AppFonts.normal(context, size: FontSize.small).copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color:
                    status == ReadingStatus.upcoming
                        ? context.calendarUpcomingDayText
                        : context.calendarDayTextSecondary,
              ),
            ),
          ),
          if (status == ReadingStatus.completed)
            Positioned(
              top: 3,
              right: 3,
              child: Icon(
                Icons.check,
                size: 9,
                color: context.calendarCompletedIcon,
              ),
            ),
          if (status == ReadingStatus.missed)
            Positioned(
              top: 3,
              right: 3,
              child: Icon(
                Icons.circle,
                size: 5,
                color: context.calendarMissedIcon.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
