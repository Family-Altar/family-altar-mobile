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
  const ReadingLoaded({
    required this.reading,
    required this.currentDate,
    required this.entries,
  });

  final Reading reading;
  final DateTime currentDate;
  final Map<String, ReadingEntry> entries; // Status tracking for all days

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
    final date = currentDate;
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
    DateTime? currentDate,
    Map<String, ReadingEntry>? entries,
  }) {
    return ReadingLoaded(
      reading: reading ?? this.reading,
      currentDate: currentDate ?? this.currentDate,
      entries: entries ?? this.entries,
    );
  }

  static String _dateToKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  @override
  List<Object> get props => [reading, currentDate, entries];
}

/// Shown when an error occurs (file not found, etc.)
class ReadingError extends ReadingState {
  const ReadingError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
