import 'package:family_altar/models/reading_entry.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/utils/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Extension for dayOfYear calculation
extension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year)).inDays + 1;
  }
}

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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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

  String _calculateCompletionPercentage(int missedDaysCount) {
    final currentDay = DateTime.now().dayOfYear;
    if (currentDay <= 0) return "0";
    final daysCompleted = currentDay - missedDaysCount;
    final percentage = (daysCompleted / currentDay) * 100;
    return percentage.clamp(0.0, 100.0).toStringAsFixed(0);
  }

  Future<void> _handleContinueReading() async {
    final lastAccessed = await Utils.getLastAccessedDay();
    final dateToOpen = lastAccessed ?? DateTime.now();
    if (mounted) {
      context.push('/reader', extra: dateToOpen);
    }
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

  // --- UI Builders ---

  Widget _buildHeader(BuildContext context) {
    final headerDate = DateFormat('MMMM yyyy').format(_currentDate);
    return Padding(
      // MODIFIED: Reduced vertical padding from 8.0 to 4.0 (Smaller Header)
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(Icons.chevron_left, color: context.calendarMonthText),
          ),
          Text(
            headerDate,
            style: AppFonts.bold(context, size: FontSize.small).copyWith(
              color: context.calendarMonthText,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(Icons.chevron_right, color: context.calendarMonthText),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(
      BuildContext context, String percentage, int missedCount) {
    return Container(
      // MODIFIED: Reduced bottom margin from 12 to 6 (Less space before button)
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Completed Stat
          Icon(Icons.check,
              size: 18, color: Colors.green.shade400),
          const SizedBox(width: 8),
          Text(
            "$percentage% Completed",
            style: AppFonts.normal(context, size: FontSize.small).copyWith(
              fontWeight: FontWeight.w600,
              color: context.calendarDayTextSecondary,
            ),
          ),
          const Spacer(),
          // Missed Stat (Only show if > 0)
          if (missedCount > 0)
            ScaleTransition(
              scale: _pulseAnimation,
              child: InkWell(
                onTap: () => context.push('/missed-days/book-1'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    // UPDATED: Using cardColor/Surface instead of Red
                    color: context.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    // UPDATED: Subtle border instead of typo
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          size: 8, color: Colors.red.shade400),
                      const SizedBox(width: 2),
                      Text(
                        "$missedCount Missed",
                        style: AppFonts.normal(context, size: FontSize.small)
                            .copyWith(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          size: 8, color: Colors.red.shade400),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Padding(
      // MODIFIED: Reduced bottom padding from 16.0 to 6.0 (Less space before calendar)
      padding: const EdgeInsets.only(bottom: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _handleContinueReading,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryButtonBGColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            shadowColor: context.primaryButtonBGColor.withOpacity(0.4),
          ),
          icon: const Icon(Icons.auto_stories, size: 20),
          label: Text(
            'Continue were you left off',
            style: AppFonts.bold(context).copyWith(
              fontSize: 12,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReadingBloc, ReadingState>(
      builder: (context, state) {
        final loadedState = state is ReadingLoaded ? state : null;
        final missedDaysCount = loadedState?.getTotalMissedDaysCount() ?? 0;
        final completionPercentage =
            _calculateCompletionPercentage(missedDaysCount);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                            // 2. Stats Dashboard
              _buildStatsBar(context, completionPercentage, missedDaysCount),


              // 3. Primary CTA
              // _buildContinueButton(context),
                            // 1. Navigation Header
              _buildHeader(context),


              // 4. Calendar Grid
              Container(
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                // MODIFIED: Reduced internal calendar padding slightly
                padding: const EdgeInsets.all(6),
                child: SfCalendar(
                  controller: _calendarController,
                  view: CalendarView.month,
                  initialDisplayDate: _currentDate,
                  headerHeight: 0,
                  backgroundColor: Colors.transparent,
                  monthViewSettings: const MonthViewSettings(
                    dayFormat: 'EEE',
                    numberOfWeeksInView: 6,
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
                  onLongPress: (details) {
                    if (details.date != null && loadedState != null) {
                      final status = loadedState.getStatus(details.date!);
                      _showLongPressDialog(context, details.date!, status);
                    }
                  },
                  monthCellBuilder: (context, details) => _CalendarCell(
                    date: details.date,
                    status: loadedState?.getStatus(details.date) ??
                        ReadingStatus.upcoming,
                  ),
                ),
              ),
            ],
          ),
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.dialogBG,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isRead ? 'Mark as Unread' : 'Mark as Read',
          style: AppFonts.bold(context).copyWith(color: context.dialogTitle),
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
            child:
                Text('Cancel', style: TextStyle(color: context.dialogCancel)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ReadingBloc>().add(
                    isRead ? MarkAsUnreadEvent(date) : MarkAsReadEvent(date),
                  );
            },
            style: FilledButton.styleFrom(
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
}

// -----------------------------------------------------------
// Extracted Widget: Clean Calendar Cell
// -----------------------------------------------------------
class _CalendarCell extends StatelessWidget {
  final DateTime date;
  final ReadingStatus status;

  const _CalendarCell({required this.date, required this.status});

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    Color borderColor;
    Color? fillColor;
    double borderWidth = 1.0; // Default subtle border width

    // STEP 1: Set a universal subtle border for ALL cells (including upcoming/default)
    borderColor = Theme.of(context).dividerColor.withOpacity(0.2);

    // STEP 2: Override border and fill based on status or 'isToday'
    if (isToday) {
      borderColor = context.calendarTodayBorder;
      fillColor = context.calendarTodayBorder.withOpacity(0.1);
      borderWidth = 2.0; // Thicker border for today
    } else {
      switch (status) {
        case ReadingStatus.completed:
          borderColor = context.calendarCompletedBorder.withOpacity(0.5);
          fillColor = context.calendarCompletedBorder.withOpacity(0.05);
          break;
        case ReadingStatus.missed:
          borderColor = context.calendarMissedBorder.withOpacity(0.5);
          fillColor = context.calendarMissedBorder.withOpacity(0.05);
          break;
        case ReadingStatus.upcoming:
        default:
          // Crucial Fix: Keep the default 'borderColor' set in Step 1.
          fillColor = Colors.transparent;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(
          color: borderColor,
          // Used determined border width. Reduced to 1.5 for non-today, but kept 2.0 for today.
          width: isToday ? 2.0 : 1.0, 
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              date.day.toString(),
              style: AppFonts.normal(context, size: FontSize.small).copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: status == ReadingStatus.upcoming
                    ? context.calendarUpcomingDayText
                    : context.calendarDayTextSecondary,
              ),
            ),
          ),
          if (status == ReadingStatus.completed)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.check,
                size: 10,
                color: context.calendarCompletedIcon,
              ),
            ),
          if (status == ReadingStatus.missed)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.circle,
                size: 6,
                color: context.calendarMissedIcon.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}