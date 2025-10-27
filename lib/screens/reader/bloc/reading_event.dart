part of 'reading_bloc.dart';

sealed class ReadingEvent extends Equatable {
  const ReadingEvent();

  @override
  List<Object> get props => [];
}

class LoadReadingEvent extends ReadingEvent {
  const LoadReadingEvent();
}

class NextReadingEvent extends ReadingEvent {
  const NextReadingEvent();
}

class PreviousReadingEvent extends ReadingEvent {
  const PreviousReadingEvent();
}
