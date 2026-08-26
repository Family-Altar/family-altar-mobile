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
  static const int _monthLayoutRowCount = 6;

  // Same shortestSide breakpoint as HomeScreen; cap width lower on tablets so
  // month cells are not oversized.
  static bool _isPhoneLayout(BuildContext context) {
    final display = View.of(context).display;
    final logicalSize = display.size / display.devicePixelRatio;
    return logicalSize.shortestSide < 600;
  }

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

  // The reading plan is a fixed 365-day cycle that repeats every year, so
  // the calendar navigates within a single Jan–Dec window (this actual
  // year) rather than scrolling freely across years.
  static DateTime get _minDate => DateTime(DateTime.now().year);
  static DateTime get _maxDate => DateTime(DateTime.now().year, 12, 31);

  static bool _isBlankedLeapDay(DateTime date) =>
      date.month == 2 && date.day == 29;

  static int _daysInYear(int year) {
    final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 366 : 365;
  }

  String _calculateCompletionProgress(ReadingLoaded? loadedState) {
    // Completed count only (excludes missed).
    // Denominator = days in current year.
    final completedCount = loadedState?.getTotalCompletedDaysCount() ?? 0;
    final daysInYear = _daysInYear(DateTime.now().year);

    return '$completedCount / $daysInYear';
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
    final target = DateTime(_currentDate.year, _currentDate.month + offset);
    if (target.isBefore(_minDate) || target.isAfter(_maxDate)) return;
    setState(() {
      _currentDate = target;
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
    final headerDate = DateFormat('MMMM').format(_currentDate);
    final navStyle = IconButton.styleFrom(
      foregroundColor: context.calendarMonthText,
    );
    final atFirstMonth = !_currentDate.isAfter(_minDate);
    final atLastMonth = !_currentDate.isBefore(DateTime(_maxDate.year, 12));
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
                    onPressed: atFirstMonth ? null : () => _changeMonth(-1),
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
                onPressed: atLastMonth ? null : () => _changeMonth(1),
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
    String progress,
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
            '$progress Read',
            style: AppFonts.normal(context, size: FontSize.small).copyWith(
              fontWeight: FontWeight.w600,
              color: context.calendarDayTextSecondary,
            ),
          ),
          const Spacer(),
          // Missed Stat (always visible and tappable)
          InkWell(
            onTap: () {
              final state = context.read<ReadingBloc>().state;
              final volumeId = state is ReadingLoaded
                  ? state.currentVolume.volumeId
                  : '1';
              context.push('/missed-days/book-$volumeId');
            },
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
        final completionProgress = _calculateCompletionProgress(loadedState);

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
            const calendarMaxWidthPhone = 680.0;
            const calendarMaxWidthTablet = 480.0;
            final isLandscape =
                MediaQuery.orientationOf(context) == Orientation.landscape;
            final isPhone = _isPhoneLayout(context);
            final tabletLandscape = !isPhone && isLandscape;
            final compact = constraints.maxHeight < 360;
            final sidePadding = compact ? 12.0 : 16.0;
            final horizontalAvail =
                (constraints.maxWidth - 2 * sidePadding).clamp(0.0, 2000.0);
            // Tablet landscape: 55% × row width, clamp 520–620.
            final calendarMaxWidth =
                isPhone
                    ? calendarMaxWidthPhone
                    : (isLandscape
                        ? (horizontalAvail * 0.55).clamp(520.0, 620.0)
                        : calendarMaxWidthTablet);
            // 12 = container's EdgeInsets.all(6) × 2 sides
            const containerPadding = 12.0;
            final viewHeaderH = tabletLandscape ? 40.0 : 36.0;

            // Width drives cell size. On phone / tablet portrait, cap by height
            // so the column fits; tablet landscape scrolls — keep larger cells.
            var calendarCardWidth =
                horizontalAvail.clamp(
                  0.0,
                  calendarMaxWidth,
                );
            var cellSize = (calendarCardWidth - containerPadding) / 7;
            const topSectionReserve = 152.0;
            final heightForCalendarCard =
                constraints.maxHeight - 8 - topSectionReserve;
            if (!tabletLandscape &&
                heightForCalendarCard > viewHeaderH + containerPadding) {
              final fromHeight =
                  (heightForCalendarCard -
                      viewHeaderH -
                      containerPadding) /
                  _monthLayoutRowCount;
              if (fromHeight > 0 && fromHeight < cellSize) {
                cellSize = fromHeight;
                calendarCardWidth = cellSize * 7 + containerPadding;
              }
            }
            final calendarCardHeight =
                viewHeaderH +
                    _monthLayoutRowCount * cellSize +
                    containerPadding;

            final calendarCard = Container(
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(6),
              child: SfCalendar(
                controller: _calendarController,
                view: CalendarView.month,
                todayHighlightColor: context.calendarCurrentWeekday,
                initialDisplayDate: _currentDate,
                minDate: _minDate,
                maxDate: _maxDate,
                headerHeight: 0,
                viewHeaderHeight: viewHeaderH,
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
                  if (details.date != null &&
                      !_isBlankedLeapDay(details.date!)) {
                    context.push('/reader', extra: details.date);
                  }
                },
                monthCellBuilder: (context, details) {
                  final cellDate = details.date;
                  // Feb 29 only exists in real leap years — blank it out so
                  // the calendar always reads as one fixed, non-leap year.
                  if (_isBlankedLeapDay(cellDate)) {
                    return const SizedBox.shrink();
                  }
                  final cellStatus =
                      loadedState?.getStatus(cellDate) ??
                      ReadingStatus.upcoming;
                  return GestureDetector(
                    onLongPress:
                        loadedState != null
                            ? () => _showLongPressDialog(
                              context,
                              cellDate,
                              cellStatus,
                            )
                            : null,
                    child: _CalendarCell(
                      date: cellDate,
                      status: cellStatus,
                      largeContent: tabletLandscape,
                    ),
                  );
                },
              ),
            );

            final topSection = <Widget>[
              _buildStatsBar(context, completionProgress, missedDaysCount),
              _buildHeader(context),
            ];

            final calendarSized = Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: calendarMaxWidth,
                ),
                child: SizedBox(
                  height: calendarCardHeight,
                  width: calendarCardWidth,
                  child: calendarCard,
                ),
              ),
            );

            // Stats/header stay fixed; only the grid scrolls. An inner Column
            // under SingleChildScrollView can still get a tight max height;
            // Expanded + one fixed-height child avoids that overflow.
            if (!constraints.maxHeight.isFinite) {
              return Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...topSection,
                    calendarSized,
                    const SizedBox(height: 12),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...topSection,
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: calendarSized,
                      ),
                    ),
                  ),
                ],
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
  const _CalendarCell({
    required this.date,
    required this.status,
    this.largeContent = false,
  });
  final DateTime date;
  final ReadingStatus status;
  final bool largeContent;

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

    final dayFontSize = largeContent ? FontSize.medium : FontSize.small;
    final cellMargin = largeContent ? 4.5 : 4.0;
    final badgeInset = largeContent ? 4.0 : 3.0;
    final checkIconSize = largeContent ? 11.0 : 9.0;
    final missedDotSize = largeContent ? 6.0 : 5.0;
    final radius = largeContent ? 9.0 : 8.0;

    return Container(
      margin: EdgeInsets.all(cellMargin),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: isToday ? 2.0 : 1.0),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              date.day.toString(),
              style: AppFonts.normal(context, size: dayFontSize).copyWith(
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
              top: badgeInset,
              right: badgeInset,
              child: Icon(
                Icons.check,
                size: checkIconSize,
                color: context.calendarCompletedIcon,
              ),
            ),
          if (status == ReadingStatus.missed)
            Positioned(
              top: badgeInset,
              right: badgeInset,
              child: Icon(
                Icons.circle,
                size: missedDotSize,
                color: context.calendarMissedIcon.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
