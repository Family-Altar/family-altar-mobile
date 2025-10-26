import 'package:equatable/equatable.dart';
import 'package:family_altar/models/reading_entry.dart';

abstract class ReadingEvent extends Equatable {
  const ReadingEvent();

  @override
  List<Object?> get props => [];
}

class ReadingLoadEvent extends ReadingEvent {
  const ReadingLoadEvent();
}

class ReadingMarkAsReadEvent extends ReadingEvent {
  const ReadingMarkAsReadEvent(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class ReadingMarkAsUnreadEvent extends ReadingEvent {
  const ReadingMarkAsUnreadEvent(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class ReadingToggleDayEvent extends ReadingEvent {
  const ReadingToggleDayEvent(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class ReadingUpdateEntryEvent extends ReadingEvent {
  const ReadingUpdateEntryEvent(this.entry);

  final ReadingEntry entry;

  @override
  List<Object?> get props => [entry];
}

class ReadingDeleteEntryEvent extends ReadingEvent {
  const ReadingDeleteEntryEvent(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

