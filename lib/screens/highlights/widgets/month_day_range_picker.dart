import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';

const _monthNames = [
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

int _daysInMonth(int month) {
  const lengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return lengths[month - 1];
}

/// Lets the user pick a start/end day-of-year for the highlights date
/// filter using month + day only — the reading plan is a fixed 365-day
/// cycle that repeats every year, so a year picker/label would be
/// meaningless here.
class MonthDayRangePicker extends StatefulWidget {
  const MonthDayRangePicker({this.initialRange, super.key});

  final DateTimeRange? initialRange;

  @override
  State<MonthDayRangePicker> createState() => _MonthDayRangePickerState();
}

class _MonthDayRangePickerState extends State<MonthDayRangePicker> {
  late int _startMonth;
  late int _startDay;
  late int _endMonth;
  late int _endDay;

  @override
  void initState() {
    super.initState();
    final range = widget.initialRange;
    _startMonth = range?.start.month ?? 1;
    _startDay = range?.start.day ?? 1;
    _endMonth = range?.end.month ?? 12;
    _endDay = range?.end.day ?? 31;
  }

  void _apply() {
    final now = DateTime.now();
    var start = DateTime(now.year, _startMonth, _startDay);
    var end = DateTime(now.year, _endMonth, _endDay);
    if (start.isAfter(end)) {
      final swap = start;
      start = end;
      end = swap;
    }
    Navigator.of(context).pop(DateTimeRange(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.textColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Date range',
                  style: AppFonts.bold(context, size: FontSize.large),
                ),
                const SizedBox(height: 16),
                _MonthDayRow(
                  label: 'From',
                  month: _startMonth,
                  day: _startDay,
                  onChanged: (month, day) {
                    setState(() {
                      _startMonth = month;
                      _startDay = day;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _MonthDayRow(
                  label: 'To',
                  month: _endMonth,
                  day: _endDay,
                  onChanged: (month, day) {
                    setState(() {
                      _endMonth = month;
                      _endDay = day;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: context.dialogCancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: context.accent,
                        ),
                        onPressed: _apply,
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthDayRow extends StatelessWidget {
  const _MonthDayRow({
    required this.label,
    required this.month,
    required this.day,
    required this.onChanged,
  });

  final String label;
  final int month;
  final int day;
  final void Function(int month, int day) onChanged;

  @override
  Widget build(BuildContext context) {
    final maxDay = _daysInMonth(month);
    final clampedDay = day > maxDay ? maxDay : day;

    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label, style: AppFonts.normal(context)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _Dropdown<int>(
            value: month,
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text(_monthNames[m - 1])),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value, clampedDay);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _Dropdown<int>(
            value: clampedDay,
            items: [
              for (var d = 1; d <= maxDay; d++)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(month, value);
            },
          ),
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: context.dialogBG,
          style: AppFonts.normal(context).copyWith(color: context.textColor),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
