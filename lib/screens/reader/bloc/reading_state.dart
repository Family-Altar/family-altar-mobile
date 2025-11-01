part of 'reading_bloc.dart';

sealed class ReadingState extends Equatable {
  const ReadingState();

  @override
  List<Object> get props => [];
}

/// Initial state before any reading is loaded
class ReadingInitial extends ReadingState {}

/// Shown while loading from local storage
class ReadingLoading extends ReadingState {}

/// Shown when the reading for the given day is successfully loaded
class ReadingLoaded extends ReadingState {
  final Reading reading;
  final int currentDayOfYear; // 1-366
  final Map<String, ReadingEntry> entries; // Status tracking for all days
  
  const ReadingLoaded({
    required this.reading,
    required this.currentDayOfYear,
    required this.entries,
  });
  
  /// Get reading entry for current day
  ReadingEntry? getCurrentEntry() {
    final date = _dayOfYearToDate(currentDayOfYear);
    return getEntry(date);
  }
  
  /// Get reading entry for a specific date
  ReadingEntry? getEntry(DateTime date) {
    final key = _dateToKey(date);
    return entries[key];
  }
  
  /// Get status for a specific date
  ReadingStatus getStatus(DateTime date) {
    final entry = getEntry(date);
    if (entry != null) {
      return entry.status;
    }
    
    // If no entry exists, determine status based on date
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (normalizedDate.isBefore(normalizedNow)) {
      return ReadingStatus.missed;
    }
    return ReadingStatus.upcoming;
  }
  
  /// Check if current day is marked as read
  bool isCurrentDayRead() {
    final date = _dayOfYearToDate(currentDayOfYear);
    return getStatus(date) == ReadingStatus.completed;
  }
  
  /// Get total missed days count
  int getTotalMissedDaysCount() {
    return entries.values.where((entry) {
      return entry.status == ReadingStatus.missed;
    }).length;
  }
  
  ReadingLoaded copyWith({
    Reading? reading,
    int? currentDayOfYear,
    Map<String, ReadingEntry>? entries,
  }) {
    return ReadingLoaded(
      reading: reading ?? this.reading,
      currentDayOfYear: currentDayOfYear ?? this.currentDayOfYear,
      entries: entries ?? this.entries,
    );
  }
  
  static DateTime _dayOfYearToDate(int dayOfYear, {int? year}) {
    final targetYear = year ?? DateTime.now().year;
    final firstDayOfYear = DateTime(targetYear, 1, 1);
    return firstDayOfYear.add(Duration(days: dayOfYear - 1));
  }
  
  static String _dateToKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  int getTotalDays() {
    final now = DateTime.now();
    final year = now.year;
    // Check if it's a leap year
    final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 366 : 365;
  }

  @override
  List<Object> get props => [reading, currentDayOfYear, entries];
}

/// Shown when an error occurs (file not found, etc.)
class ReadingError extends ReadingState {
  final String message;

  const ReadingError(this.message);

  @override
  List<Object> get props => [message];
}
