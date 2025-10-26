import 'package:equatable/equatable.dart';
import 'package:family_altar/models/reading_entry.dart';

abstract class ReadingState extends Equatable {
  const ReadingState();

  @override
  List<Object?> get props => [];
}

/// Initial state 
class ReadingInitialState extends ReadingState {
  const ReadingInitialState();
}

/// State when reading data is being loaded
class ReadingLoadingState extends ReadingState {
  const ReadingLoadingState();
}

/// State when reading data is successfully loaded
class ReadingLoadedState extends ReadingState {
  const ReadingLoadedState({
    required this.entries,
  });

  /// Map of reading entries indexed by date string
  /// Key "yyyy-MM-dd" (e.g., "2024-03-15")
  final Map<String, ReadingEntry> entries;


  ReadingEntry? getEntry(DateTime date) {
    final key = _dateToKey(date);
    return entries[key];
  }
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

  bool isRead(DateTime date) {
    return getStatus(date) == ReadingStatus.completed;
  }

  int getTotalMissedDaysCount() {
    return entries.values.where((entry) {
      return entry.status == ReadingStatus.missed;
    }).length;
  }

  ReadingLoadedState copyWith({
    Map<String, ReadingEntry>? entries,
  }) {
    return ReadingLoadedState(
      entries: entries ?? this.entries,
    );
  }
  static String _dateToKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day'; // yyyy-MM-dd
  }

  @override
  List<Object?> get props => [entries];
}

class ReadingErrorState extends ReadingState {
  const ReadingErrorState(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

