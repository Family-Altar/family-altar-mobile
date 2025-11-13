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
  }

  final ReadingRepository readingRepository;
  
  static const String _storageKey = 'reading_entries';
  static const String _lastAccessedKey = 'last_accessed_day';
  
  Future<void> _onLoad(
    LoadReadingEvent event,
    Emitter<ReadingState> emit,
  ) async {
    emit(ReadingLoading());
    
    try {
      // Determine which day to load
      final dayOfYear = event.dayOfYear ?? _getCurrentDayOfYear();
      
      // Load reading entries for status tracking
      final entries = await _loadEntries();
      
      // Load the actual reading content
      final reading = await readingRepository.fetchReading(
        dayOfYear: dayOfYear,
      );
      
      // Save last accessed day
      final date = _dayOfYearToDate(dayOfYear);
      await _saveLastAccessedDay(date);
      
      emit(ReadingLoaded(
        reading: reading,
        currentDayOfYear: dayOfYear,
        entries: entries,
      ));
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
    final totalDays = currentState.getTotalDays();
    final nextDay = currentState.currentDayOfYear < totalDays 
        ? currentState.currentDayOfYear + 1 
        : 1;
    
    emit(ReadingLoading());
    
    try {
      final reading = await readingRepository.fetchReading(dayOfYear: nextDay);
      final date = _dayOfYearToDate(nextDay);
      await _saveLastAccessedDay(date);
      
      emit(currentState.copyWith(
        reading: reading,
        currentDayOfYear: nextDay,
      ));
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
    final totalDays = currentState.getTotalDays();
    final prevDay = currentState.currentDayOfYear > 1 
        ? currentState.currentDayOfYear - 1 
        : totalDays;
    
    emit(ReadingLoading());
    
    try {
      final reading = await readingRepository.fetchReading(dayOfYear: prevDay);
      final date = _dayOfYearToDate(prevDay);
      await _saveLastAccessedDay(date);
      
      emit(currentState.copyWith(
        reading: reading,
        currentDayOfYear: prevDay,
      ));
    } on Exception catch (e) {
      emit(ReadingError('Failed to load previous reading: $e'));
    }
  }
  
  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoaded) return;
    
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
    
    final updatedEntries = Map<String, ReadingEntry>.from(
      currentState.entries,
    )..remove(dateKey);
    
    // Remove the entry so it becomes unread
    // (upcoming if future, missed if past)
    
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
  
  // ===== Helper Methods =====
  
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
      
      // Auto-mark missed days
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
    
    final updatedEntries = Map<String, ReadingEntry>.from(currentEntries);
    
    var currentDate = startOfYear;
    while (currentDate.isBefore(today)) {
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
  
  static Future<DateTime?> getLastAccessedDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastAccessedKey);
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
    } on Exception {
      // Error getting last accessed day - fail silently
    }
    return null;
  }
  
  int _getCurrentDayOfYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year);
    final difference = now.difference(startOfYear).inDays;
    return difference + 1; // Days are 1-indexed
  }
  
  DateTime _dayOfYearToDate(int dayOfYear, {int? year}) {
    final targetYear = year ?? DateTime.now().year;
    final firstDayOfYear = DateTime(targetYear);
    return firstDayOfYear.add(Duration(days: dayOfYear - 1));
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
}
