import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/reader/domain/page.dart';

part 'foreword_preface_event.dart';
part 'foreword_preface_state.dart';

class ForewordPrefaceBloc extends Bloc<PageEvent, ForewordPrefaceState> {
  ForewordPrefaceBloc({required this.readingRepository})
    : super(PageInitial()) {
    on<LoadPageEvent>(_onLoad);
    on<NextPageEvent>(_onNext);
    on<PreviousPageEvent>(_onPrevious);
  }

  final ReadingRepository readingRepository;

  static const List<Section> _sectionOrder = [
    Section.foreword,
    Section.preface,
    Section.dailyReading,
  ];

  Future<void> _onLoad(
    LoadPageEvent event,
    Emitter<ForewordPrefaceState> emit,
  ) async {
    await _loadSection(event.sect, emit);
  }

  Future<void> _onNext(
    NextPageEvent event,
    Emitter<ForewordPrefaceState> emit,
  ) async {
    if (state is! PageLoaded) return;
    final currentState = state as PageLoaded;
    final nextSection = _nextSection(currentState.section);
    if (nextSection == null) return;
    await _loadSection(nextSection, emit);
  }

  Future<void> _onPrevious(
    PreviousPageEvent event,
    Emitter<ForewordPrefaceState> emit,
  ) async {
    if (state is! PageLoaded) return;
    final currentState = state as PageLoaded;
    final previousSection = _previousSection(currentState.section);
    if (previousSection == null) return;
    await _loadSection(previousSection, emit);
  }

  Future<void> _loadSection(
    Section section,
    Emitter<ForewordPrefaceState> emit,
  ) async {
    emit(PageLoading());
    try {
      final page = await readingRepository.fetchPage(sect: section);
      emit(
        PageLoaded(
          page: page,
          section: section,
          hasNext: _hasNext(section),
          hasPrevious: _hasPrevious(section),
        ),
      );
    } on Exception catch (e) {
      emit(PageError('Failed to load $section: $e'));
    }
  }

  Section? _nextSection(Section section) {
    final index = _sectionOrder.indexOf(section);
    if (index == -1 || index >= _sectionOrder.length - 1) {
      return null;
    }
    return _sectionOrder[index + 1];
  }

  Section? _previousSection(Section section) {
    final index = _sectionOrder.indexOf(section);
    if (index <= 0) return null;
    return _sectionOrder[index - 1];
  }

  bool _hasNext(Section section) => _nextSection(section) != null;

  bool _hasPrevious(Section section) => _previousSection(section) != null;
}
