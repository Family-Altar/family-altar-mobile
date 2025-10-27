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
  final String reading;

  const ReadingLoaded({required this.reading});

  @override
  List<Object> get props => [reading];
}

// /// Shown when an error occurs (file not found, etc.)
// class ReadingError extends ReadingState {
//   final String message;

//   const ReadingError(this.message);

//   @override
//   List<Object?> get props => [message];
// }
