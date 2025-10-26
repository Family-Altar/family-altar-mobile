import 'dart:convert';

import 'package:family_altar/models/reading_entry.dart';
import 'package:family_altar/screens/reading/bloc/reading_event.dart';
import 'package:family_altar/screens/reading/bloc/reading_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  ReadingBloc() : super(const ReadingInitialState()) {
    on<ReadingLoadEvent>(_onLoad);
    on<ReadingMarkAsReadEvent>(_onMarkAsRead);
    on<ReadingMarkAsUnreadEvent>(_onMarkAsUnread);
    on<ReadingToggleDayEvent>(_onToggleDay);
    on<ReadingUpdateEntryEvent>(_onUpdateEntry);
    on<ReadingDeleteEntryEvent>(_onDeleteEntry);
  }

  static const String _storageKey = 'reading_entries';
  static const String _lastAccessedKey = 'last_accessed_day';

  Future<void> _onLoad(
    ReadingLoadEvent event,
    Emitter<ReadingState> emit,
  ) async {
    emit(const ReadingLoadingState());
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      var entries = <String, ReadingEntry>{};
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        
        for (final entry in jsonData.entries) {
          entries[entry.key] = ReadingEntry.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }

      entries = await _autoMarkMissedDays(entries);

      emit(ReadingLoadedState(entries: entries));
      
      await _saveToStorage(entries);
    } on Exception catch (e) {
      emit(ReadingErrorState('Failed to load reading data: $e'));
    }
  }

  Future<void> _onMarkAsRead(
    ReadingMarkAsReadEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoadedState) return;

    final currentState = state as ReadingLoadedState;
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
    ReadingMarkAsUnreadEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoadedState) return;

    final currentState = state as ReadingLoadedState;
    final dateKey = _dateToKey(event.date);
    
    final updatedEntries = Map<String, ReadingEntry>.from(currentState.entries);
    
    updatedEntries[dateKey] = ReadingEntry(
      date: _normalizeDate(event.date),
      status: ReadingStatus.missed,
    );

    emit(currentState.copyWith(entries: updatedEntries));
    await _saveToStorage(updatedEntries);
  }

  Future<void> _onToggleDay(
    ReadingToggleDayEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoadedState) return;

    final currentState = state as ReadingLoadedState;
    final dateKey = _dateToKey(event.date);
    final existingEntry = currentState.entries[dateKey];
    
    final updatedEntries = Map<String, ReadingEntry>.from(
      currentState.entries,
    );
    
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

  Future<void> _onUpdateEntry(
    ReadingUpdateEntryEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoadedState) return;

    final currentState = state as ReadingLoadedState;
    final dateKey = _dateToKey(event.entry.date);
    
    final updatedEntries = Map<String, ReadingEntry>.from(currentState.entries);
    updatedEntries[dateKey] = event.entry;

    emit(currentState.copyWith(entries: updatedEntries));
    await _saveToStorage(updatedEntries);
  }

  Future<void> _onDeleteEntry(
    ReadingDeleteEntryEvent event,
    Emitter<ReadingState> emit,
  ) async {
    if (state is! ReadingLoadedState) return;

    final currentState = state as ReadingLoadedState;
    final dateKey = _dateToKey(event.date);
    
    final updatedEntries = Map<String, ReadingEntry>.from(currentState.entries)
      ..remove(dateKey);

    emit(currentState.copyWith(entries: updatedEntries));
    await _saveToStorage(updatedEntries);
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

  String _dateToKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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

  static Future<void> saveLastAccessedDay(DateTime date) async {
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
}

