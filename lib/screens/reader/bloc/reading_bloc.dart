import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_altar/models/reading_entry.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/reader/domain/reading.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'reading_event.dart';
part 'reading_state.dart';

class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  ReadingBloc({required this.readingRepository}) : super(ReadingInitial()) {
    on<LoadReadingEvent>(_onLoad);
    on<NextReadingEvent>(_onNext);
    on<PreviousReadingEvent>(_onPrevious);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAsUnreadEvent>(_onMarkAsUnread);
    on<ToggleDayEvent>(_onToggleDay);
    on<ResetReadingProgressEvent>(_onResetReadingProgress);
  }

  final ReadingRepository readingRepository;
  final Map<DateTime, Reading> _readingCache = {};

  static const String _storageKey = 'reading_entries';
  static const String _lastAccessedKey = 'last_accessed_day';
  static const String _firstLaunchKey = 'first_launch_date';
  
  Future<void> initializeFirstLaunchDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_firstLaunchKey)) {
        // Only set first launch if not already set; also require no existing
        // reading entries in shared preferences.
        final entries = await _loadEntries();
        if (entries.isEmpty) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          await prefs.setString(_firstLaunchKey, today.toIso8601String());
        }
      }
    } on Exception{
            // Error setting first launch date - fail silently

    }
  }

  Future<void> _onLoad(
    LoadReadingEvent event,
    Emitter<ReadingState> emit,
  ) async {
    emit(ReadingLoading());

    try {
      final entries = await _loadEntries();
      final normalizedDate = _normalizeDate(event.date);
      _readingCache
        ..clear()
        ..[normalizedDate] = await readingRepository.fetchReading(
          date: normalizedDate,
        );
      await _saveLastAccessedDay(normalizedDate);

      final firstLaunchDate = await _getFirstLaunchDate();

      emit(
        ReadingLoaded(
          reading: _readingCache[normalizedDate]!,
          currentDate: normalizedDate,
          entries: entries,
          firstLaunchDate: firstLaunchDate,
        ),
      );

      await _prefetchSurroundingDays(normalizedDate);
    } on Exception catch (e) {
      emit(ReadingError('Failed to load reading: $e'));
    }
  }

  Future<void> _onNext(
    NextReadingEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoaded) return;

    final currentState = state as ReadingLoaded;

    final nextDate = _normalizeDate(
      currentState.currentDate.add(const Duration(days: 1)),
    );

    try {
      final reading = await _getOrFetchReading(nextDate);
      await _saveLastAccessedDay(nextDate);

      emit(currentState.copyWith(reading: reading, currentDate: nextDate));
      await _prefetchSurroundingDays(nextDate);
    } on Exception catch (e) {
      emit(ReadingError('Failed to load next reading: $e'));
    }
  }

  Future<void> _onPrevious(
    PreviousReadingEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoaded) return;

    final currentState = state as ReadingLoaded;

    final prevDate = _normalizeDate(
      currentState.currentDate.subtract(const Duration(days: 1)),
    );

    try {
      final reading = await _getOrFetchReading(prevDate);
      await _saveLastAccessedDay(prevDate);

      emit(currentState.copyWith(reading: reading, currentDate: prevDate));
      await _prefetchSurroundingDays(prevDate);
    } on Exception catch (e) {
      emit(ReadingError('Failed to load previous reading: $e'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<ReadingState> emit,
  ) async {
    final currentState = state as ReadingLoaded;
    final dateKey = _dateToKey(event.date);

    final updatedEntries = Map<String, ReadingEntry>.from(currentState.entries);
    updatedEntries[dateKey] = ReadingEntry(
      date: _normalizeDate(event.date),
      status: ReadingStatus.completed,
    );

    emit(currentState.copyWith(entries: updatedEntries));
    await _saveToStorage(updatedEntries);
  }

  Future<void> _onMarkAsUnread(
    MarkAsUnreadEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoaded) return;

    final currentState = state as ReadingLoaded;
    final dateKey = _dateToKey(event.date);

    final updatedEntries = Map<String, ReadingEntry>.from(currentState.entries)
      ..remove(dateKey);
    emit(currentState.copyWith(entries: updatedEntries));
    await _saveToStorage(updatedEntries);
  }

  Future<void> _onToggleDay(
    ToggleDayEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoaded) return;

    final currentState = state as ReadingLoaded;
    final dateKey = _dateToKey(event.date);
    final existingEntry = currentState.entries[dateKey];

    final updatedEntries = Map<String, ReadingEntry>.from(currentState.entries);

    if (existingEntry == null ||
        existingEntry.status != ReadingStatus.completed) {
      updatedEntries[dateKey] = ReadingEntry(
        date: _normalizeDate(event.date),
        status: ReadingStatus.completed,
      );
    } else {
      updatedEntries[dateKey] = ReadingEntry(
        date: _normalizeDate(event.date),
        status: ReadingStatus.missed,
      );
    }

    emit(currentState.copyWith(entries: updatedEntries));
    await _saveToStorage(updatedEntries);
  }

  Future<void> _onResetReadingProgress(
    ResetReadingProgressEvent event,
    Emitter<ReadingState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear all reading entries
      await prefs.remove(_storageKey);
      await prefs.remove(_lastAccessedKey);
      await prefs.remove(_firstLaunchKey);
      await initializeFirstLaunchDate();
      if (state is ReadingLoaded) {
        final currentState = state as ReadingLoaded;
        final entries = await _loadEntries();
        final firstLaunchDate = await _getFirstLaunchDate();
        emit(
          currentState.copyWith(
            entries: entries,
            firstLaunchDate: firstLaunchDate,
          ),
        );
      }
    } on Exception {
      // Error resetting reading progress - fail silently
    }
  }

  Future<Map<String, ReadingEntry>> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      final entries = <String, ReadingEntry>{};

      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;

        for (final entry in jsonData.entries) {
          entries[entry.key] = ReadingEntry.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
      return await _autoMarkMissedDays(entries);
    } on Exception {
      return {};
    }
  }

  Future<void> _saveToStorage(Map<String, ReadingEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = <String, dynamic>{};

      entries.forEach((key, entry) {
        jsonData[key] = entry.toJson();
      });

      final jsonString = json.encode(jsonData);
      await prefs.setString(_storageKey, jsonString);
    } on Exception {
      // Error saving reading data - fail silently
    }
  }

  Future<Map<String, ReadingEntry>> _autoMarkMissedDays(
    Map<String, ReadingEntry> currentEntries,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfYear = DateTime(now.year);
    final firstLaunchDate = await _getFirstLaunchDate();

    final updatedEntries = Map<String, ReadingEntry>.from(currentEntries);

    var currentDate = startOfYear;
    while (currentDate.isBefore(today)) {
      // Skip days before the app was first launched - keep them unread
      if (currentDate.isBefore(firstLaunchDate)) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      final dateKey = _dateToKey(currentDate);
      final existingEntry = updatedEntries[dateKey];

      if (existingEntry == null) {
        updatedEntries[dateKey] = ReadingEntry(
          date: currentDate,
          status: ReadingStatus.missed,
        );
      } else if (existingEntry.status == ReadingStatus.upcoming) {
        updatedEntries[dateKey] = existingEntry.copyWith(
          status: ReadingStatus.missed,
        );
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return updatedEntries;
  }

  Future<void> _saveLastAccessedDay(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastAccessedKey, date.toIso8601String());
    } on Exception {
      // Error saving last accessed day - fail silently
    }
  }

  Future<Reading> _getOrFetchReading(DateTime date) async {
    final normalized = _normalizeDate(date);
    final cached = _readingCache[normalized];
    if (cached != null) return cached;

    final reading = await readingRepository.fetchReading(date: normalized);
    _readingCache[normalized] = reading;
    return reading;
  }

  Future<void> _prefetchSurroundingDays(DateTime date) async {
    final prev = date.subtract(const Duration(days: 1));
    final next = date.add(const Duration(days: 1));

    await Future.wait([_maybePrefetch(prev), _maybePrefetch(next)]);
  }

  Future<void> _maybePrefetch(DateTime date) async {
    final normalized = _normalizeDate(date);
    if (_readingCache.containsKey(normalized)) return;

    try {
      _readingCache[normalized] = await readingRepository.fetchReading(
        date: normalized,
      );
    } on Exception {
      // Ignore prefetch failures - we'll fetch on demand later
    }
  }

  String _dateToKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<DateTime> _getFirstLaunchDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_firstLaunchKey);
      if (dateString != null) {
        final date = DateTime.parse(dateString);
        return DateTime(date.year, date.month, date.day);
      }
    } on Exception {
      // Error getting first launch date - fail silently
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
