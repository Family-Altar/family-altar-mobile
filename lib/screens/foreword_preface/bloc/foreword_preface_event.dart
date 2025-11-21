part of 'foreword_preface_bloc.dart';

sealed class PageEvent extends Equatable {
  const PageEvent();

  @override
  List<Object> get props => [];
}

class LoadPageEvent extends PageEvent {
  const LoadPageEvent({required this.sect});

  final Section sect;

  @override
  List<Object> get props => [sect];
}

/// Navigate to next day
class NextPageEvent extends PageEvent {
  const NextPageEvent();
}

/// Navigate to previous day
class PreviousPageEvent extends PageEvent {
  const PreviousPageEvent();
}
