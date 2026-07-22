import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_altar/models/volume.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/reader/domain/page.dart';

part 'foreword_preface_event.dart';
part 'foreword_preface_state.dart';

class ForewordPrefaceBloc extends Bloc<PageEvent, ForewordPrefaceState> {
  ForewordPrefaceBloc({
    required this.readingRepository,
    required this.volume,
  }) : super(PageInitial()) {
    _sectionOrder = _orderedSectionsFor(volume);
    on<LoadPageEvent>(_onLoad);
    on<NextPageEvent>(_onNext);
    on<PreviousPageEvent>(_onPrevious);
  }

  final ReadingRepository readingRepository;
  final Volume volume;
  final Map<Section, Page> _pageCache = {};
  late final List<Section> _sectionOrder;

  static List<Section> _orderedSectionsFor(Volume v) => switch (v) {
    Volume.one => [Section.foreword, Section.preface, Section.dailyReading],
    Volume.two => [Section.preface, Section.dailyReading],
    Volume.three => [Section.preface, Section.dailyReading],
  };

  Future<void> _onLoad(
    LoadPageEvent event,
    Emitter<ForewordPrefaceState> emit,
  ) async {
    await _loadSection(event.sect, emit, showLoading: true);
  }

  Future<void> _onNext(
    NextPageEvent event,
    Emitter<ForewordPrefaceState> emit,
  ) async {
    if (state is! PageLoaded) return;
    final currentState = state as PageLoaded;
    final nextSection = _nextSection(currentState.section);
    if (nextSection == null) return;
    await _loadSection(nextSection, emit, showLoading: false);
  }

  Future<void> _onPrevious(
    PreviousPageEvent event,
    Emitter<ForewordPrefaceState> emit,
  ) async {
    if (state is! PageLoaded) return;
    final currentState = state as PageLoaded;
    final previousSection = _previousSection(currentState.section);
    if (previousSection == null) return;
    await _loadSection(previousSection, emit, showLoading: false);
  }

  Future<void> _loadSection(
    Section section,
    Emitter<ForewordPrefaceState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(PageLoading());
    }
    try {
      final page = await _getOrFetchPage(section);
      emit(
        PageLoaded(
          page: page,
          section: section,
          hasNext: _hasNext(section),
          hasPrevious: _hasPrevious(section),
        ),
      );
      await _prefetchSurroundingSections(section);
    } on Exception catch (e) {
      emit(PageError('Failed to load $section: $e'));
    }
  }

  Section? _nextSection(Section section) {
    final index = _sectionOrder.indexOf(section);
    if (index == -1 || index >= _sectionOrder.length - 1) return null;
    return _sectionOrder[index + 1];
  }

  Section? _previousSection(Section section) {
    final index = _sectionOrder.indexOf(section);
    if (index <= 0) return null;
    return _sectionOrder[index - 1];
  }

  bool _hasNext(Section section) => _nextSection(section) != null;

  bool _hasPrevious(Section section) => _previousSection(section) != null;

  Future<Page> _getOrFetchPage(Section section) async {
    final cached = _pageCache[section];
    if (cached != null) return cached;

    final page = await readingRepository.fetchPage(
      sect: section,
      volume: volume,
    );
    _pageCache[section] = page;
    return page;
  }

  Future<void> _prefetchSurroundingSections(Section section) async {
    final futures = <Future<void>>[];
    final next = _nextSection(section);
    final previous = _previousSection(section);

    if (next != null) futures.add(_maybePrefetch(next));
    if (previous != null) futures.add(_maybePrefetch(previous));

    await Future.wait(futures);
  }

  Future<void> _maybePrefetch(Section section) async {
    if (_pageCache.containsKey(section)) return;
    try {
      _pageCache[section] = await readingRepository.fetchPage(
        sect: section,
        volume: volume,
      );
    } on Exception {
      // ignore prefetch errors
    }
  }
}
