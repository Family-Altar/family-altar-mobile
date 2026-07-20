part of 'reading_bloc.dart';

sealed class ReadingEvent extends Equatable {
  const ReadingEvent();

  @override
  List<Object> get props => [];
}

/// Switch between volumes
class SwitchVolumeEvent extends ReadingEvent {
  const SwitchVolumeEvent(this.volume);

  final Volume volume;

  @override
  List<Object> get props => [volume];
}

/// Load reading for a specific day (1-366)
class LoadReadingEvent extends ReadingEvent {
  const LoadReadingEvent({required this.date});

  final DateTime date; // If null, loads today's reading

  @override
  List<Object> get props => [date];
}

/// Navigate to next day
class NextReadingEvent extends ReadingEvent {
  const NextReadingEvent();
}

/// Navigate to previous day
class PreviousReadingEvent extends ReadingEvent {
  const PreviousReadingEvent();
}

/// Mark a specific date as read
class MarkAsReadEvent extends ReadingEvent {
  const MarkAsReadEvent(this.date);

  final DateTime date;

  @override
  List<Object> get props => [date];
}

/// Mark a specific date as unread/missed
class MarkAsUnreadEvent extends ReadingEvent {
  const MarkAsUnreadEvent(this.date);

  final DateTime date;

  @override
  List<Object> get props => [date];
}

/// Toggle read status for a date
class ToggleDayEvent extends ReadingEvent {
  const ToggleDayEvent(this.date);

  final DateTime date;

  @override
  List<Object> get props => [date];
}

/// Reset all reading progress
class ResetReadingProgressEvent extends ReadingEvent {
  const ResetReadingProgressEvent();
}
