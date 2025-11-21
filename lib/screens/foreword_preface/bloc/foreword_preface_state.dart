part of 'foreword_preface_bloc.dart';

sealed class ForewordPrefaceState extends Equatable {
  const ForewordPrefaceState();

  @override
  List<Object> get props => [];
}

class PageInitial extends ForewordPrefaceState {}

class PageLoading extends ForewordPrefaceState {}

class PageLoaded extends ForewordPrefaceState {
  const PageLoaded({
    required this.page,
    required this.section,
    required this.hasNext,
    required this.hasPrevious,
  });

  final Page page;
  final Section section;
  final bool hasNext;
  final bool hasPrevious;

  PageLoaded copyWith({
    Page? page,
    Section? section,
    bool? hasNext,
    bool? hasPrevious,
  }) {
    return PageLoaded(
      page: page ?? this.page,
      section: section ?? this.section,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
    );
  }

  @override
  List<Object> get props => [page, section, hasNext, hasPrevious];
}

class PageError extends ForewordPrefaceState {
  const PageError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
