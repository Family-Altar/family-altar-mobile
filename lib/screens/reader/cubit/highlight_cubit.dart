import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_altar/models/volume.dart';
import 'package:family_altar/screens/reader/domain/text_highlight.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _highlightsStorageKey(Volume volume) =>
    'highlights${volume.storageSuffix}';

/// Highlights are keyed by month+day only, not the full calendar date —
/// the reading plan is a fixed 365-day cycle that repeats every year, so
/// a highlight made on "January 1" should still show up on any January 1,
/// regardless of which real year it was created in or is being viewed in.
String _highlightDateKey(DateTime date) => DateFormat('MM-dd').format(date);

final _legacyFullDateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

DateTime _dateFromDateKey(String key) {
  final parts = key.split('-');
  final month = int.parse(parts[parts.length - 2]);
  final day = int.parse(parts[parts.length - 1]);
  return DateTime(DateTime.now().year, month, day);
}

Map<String, dynamic> _migrateLegacyDateKeys(Map<String, dynamic> blob) {
  if (!blob.keys.any(_legacyFullDateKeyPattern.hasMatch)) return blob;

  final migrated = <String, dynamic>{};
  for (final entry in blob.entries) {
    final newKey =
        _legacyFullDateKeyPattern.hasMatch(entry.key)
            ? entry.key.substring(5)
            : entry.key;

    final existing = migrated[newKey] as Map<String, dynamic>?;
    if (existing == null) {
      migrated[newKey] = entry.value;
      continue;
    }

    final incoming = entry.value as Map<String, dynamic>;
    final merged = Map<String, dynamic>.from(existing);
    for (final fieldEntry in incoming.entries) {
      final existingList = (merged[fieldEntry.key] as List<dynamic>?) ?? [];
      merged[fieldEntry.key] = [
        ...existingList,
        ...fieldEntry.value as List<dynamic>,
      ];
    }
    migrated[newKey] = merged;
  }
  return migrated;
}

Future<Map<String, dynamic>> _loadHighlightsBlob(Volume volume) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_highlightsStorageKey(volume));
    if (jsonString == null || jsonString.isEmpty) return {};
    final blob = json.decode(jsonString) as Map<String, dynamic>;

    final migrated = _migrateLegacyDateKeys(blob);
    if (!identical(migrated, blob)) {
      await prefs.setString(
        _highlightsStorageKey(volume),
        json.encode(migrated),
      );
    }
    return migrated;
  } on Exception {
    return {};
  }
}

class HighlightState extends Equatable {
  const HighlightState({
    required this.currentDate,
    required this.currentVolume,
    required this.highlightsByField,
  });

  factory HighlightState.empty() => HighlightState(
    currentDate: DateTime(2000),
    currentVolume: Volume.one,
    highlightsByField: const {},
  );

  final DateTime currentDate;
  final Volume currentVolume;
  final Map<HighlightField, List<TextHighlight>> highlightsByField;

  List<TextHighlight> forField(HighlightField field) =>
      highlightsByField[field] ?? const [];

  HighlightState copyWith({
    DateTime? currentDate,
    Volume? currentVolume,
    Map<HighlightField, List<TextHighlight>>? highlightsByField,
  }) => HighlightState(
    currentDate: currentDate ?? this.currentDate,
    currentVolume: currentVolume ?? this.currentVolume,
    highlightsByField: highlightsByField ?? this.highlightsByField,
  );

  @override
  List<Object?> get props => [currentDate, currentVolume, highlightsByField];
}

class HighlightCubit extends Cubit<HighlightState> {
  HighlightCubit() : super(HighlightState.empty());

  Future<void> loadForDate({
    required DateTime date,
    required Volume volume,
  }) async {
    final blob = await _loadHighlightsBlob(volume);
    final dayEntry =
        blob[_highlightDateKey(date)] as Map<String, dynamic>? ?? {};

    final highlightsByField = <HighlightField, List<TextHighlight>>{};
    for (final entry in dayEntry.entries) {
      final field = HighlightField.fromStorageKey(entry.key);
      if (field == null) continue;
      final list =
          (entry.value as List<dynamic>)
              .map((e) => TextHighlight.fromJson(e as Map<String, dynamic>))
              .toList();
      if (list.isNotEmpty) highlightsByField[field] = list;
    }

    emit(
      HighlightState(
        currentDate: date,
        currentVolume: volume,
        highlightsByField: highlightsByField,
      ),
    );
  }

  Future<void> addHighlight({
    required HighlightField field,
    required int start,
    required int end,
    required String colorId,
    required String snippet,
    String? id,
  }) async {
    final existing = state.forField(field);
    final withoutOverlaps =
        existing.where((h) => !h.overlaps(start, end)).toList();
    final updated = [
      ...withoutOverlaps,
      TextHighlight(
        id: id ?? generateHighlightId(),
        start: start,
        end: end,
        colorId: colorId,
        snippet: snippet,
      ),
    ]..sort((a, b) => a.start.compareTo(b.start));

    await _updateField(field, updated);
  }

  Future<void> removeHighlight({
    required HighlightField field,
    required TextHighlight highlight,
  }) async {
    final updated =
        state.forField(field).where((h) => h.id != highlight.id).toList();
    await _updateField(field, updated);
  }

  Future<void> changeHighlightColor({
    required HighlightField field,
    required TextHighlight highlight,
    required String newColorId,
  }) async {
    final updated =
        state.forField(field).map((h) {
          if (h.id == highlight.id) {
            return TextHighlight(
              id: h.id,
              start: h.start,
              end: h.end,
              colorId: newColorId,
              snippet: h.snippet,
              note: h.note,
            );
          }
          return h;
        }).toList();
    await _updateField(field, updated);
  }

  Future<void> setNote({
    required HighlightField field,
    required TextHighlight highlight,
    required String? note,
  }) async {
    final updated =
        state.forField(field).map((h) {
          if (h.id == highlight.id) {
            return TextHighlight(
              id: h.id,
              start: h.start,
              end: h.end,
              colorId: h.colorId,
              snippet: h.snippet,
              note: note,
            );
          }
          return h;
        }).toList();
    await _updateField(field, updated);
  }

  Future<void> _updateField(
    HighlightField field,
    List<TextHighlight> highlights,
  ) async {
    final highlightsByField = Map<HighlightField, List<TextHighlight>>.from(
      state.highlightsByField,
    );
    if (highlights.isEmpty) {
      highlightsByField.remove(field);
    } else {
      highlightsByField[field] = highlights;
    }

    emit(state.copyWith(highlightsByField: highlightsByField));
    await _persist(highlightsByField);
  }

  Future<void> _persist(
    Map<HighlightField, List<TextHighlight>> highlightsByField,
  ) async {
    try {
      final blob = await _loadHighlightsBlob(state.currentVolume);
      final dateKey = _highlightDateKey(state.currentDate);

      if (highlightsByField.isEmpty) {
        blob.remove(dateKey);
      } else {
        blob[dateKey] = {
          for (final entry in highlightsByField.entries)
            entry.key.storageKey: entry.value.map((h) => h.toJson()).toList(),
        };
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _highlightsStorageKey(state.currentVolume),
        json.encode(blob),
      );
    } on Exception {
      // fail silently
    }
  }
}

class HighlightListEntry {
  const HighlightListEntry({
    required this.date,
    required this.field,
    required this.highlight,
  });

  final DateTime date;
  final HighlightField field;
  final TextHighlight highlight;
}

/// One-shot query across every date for [volume] — not reactive cubit
/// state, since it's only needed to populate the highlights list screen.
Future<List<HighlightListEntry>> loadAllHighlights(Volume volume) async {
  final blob = await _loadHighlightsBlob(volume);
  final entries = <HighlightListEntry>[];

  try {
    for (final dayEntry in blob.entries) {
      final date = _dateFromDateKey(dayEntry.key);
      final fields = dayEntry.value as Map<String, dynamic>;

      for (final fieldEntry in fields.entries) {
        final field = HighlightField.fromStorageKey(fieldEntry.key);
        if (field == null) continue;

        for (final raw in fieldEntry.value as List<dynamic>) {
          entries.add(
            HighlightListEntry(
              date: date,
              field: field,
              highlight: TextHighlight.fromJson(raw as Map<String, dynamic>),
            ),
          );
        }
      }
    }
  } on Exception {
    return [];
  }

  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

Future<void> clearAllHighlights(Volume volume) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_highlightsStorageKey(volume));
  } on Exception {
    // fail silently
  }
}

Future<void> _mutateHighlightEntry(
  Volume volume,
  HighlightListEntry entry,
  TextHighlight? Function(TextHighlight current) transform,
) async {
  try {
    final blob = await _loadHighlightsBlob(volume);
    final dateKey = _highlightDateKey(entry.date);
    final dayEntry = blob[dateKey] as Map<String, dynamic>?;
    if (dayEntry == null) return;

    final fieldKey = entry.field.storageKey;
    final list = (dayEntry[fieldKey] as List<dynamic>?) ?? const [];
    final updatedList =
        list
            .map((raw) => TextHighlight.fromJson(raw as Map<String, dynamic>))
            .map((h) => h.id == entry.highlight.id ? transform(h) : h)
            .whereType<TextHighlight>()
            .map((h) => h.toJson())
            .toList();

    if (updatedList.isEmpty) {
      dayEntry.remove(fieldKey);
    } else {
      dayEntry[fieldKey] = updatedList;
    }

    if (dayEntry.isEmpty) {
      blob.remove(dateKey);
    } else {
      blob[dateKey] = dayEntry;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_highlightsStorageKey(volume), json.encode(blob));
  } on Exception {
    // fail silently
  }
}

/// Deletes a single [HighlightListEntry] directly from storage.
Future<void> removeHighlightEntry(Volume volume, HighlightListEntry entry) =>
    _mutateHighlightEntry(volume, entry, (_) => null);

/// Changes the color of a single [HighlightListEntry] directly in storage.
Future<void> changeHighlightEntryColor(
  Volume volume,
  HighlightListEntry entry,
  String newColorId,
) => _mutateHighlightEntry(
  volume,
  entry,
  (h) => TextHighlight(
    id: h.id,
    start: h.start,
    end: h.end,
    colorId: newColorId,
    snippet: h.snippet,
    note: h.note,
  ),
);

/// Sets (or clears, when [note] is null) the note on a single
/// [HighlightListEntry] directly in storage.
Future<void> setHighlightEntryNote(
  Volume volume,
  HighlightListEntry entry,
  String? note,
) => _mutateHighlightEntry(
  volume,
  entry,
  (h) => TextHighlight(
    id: h.id,
    start: h.start,
    end: h.end,
    colorId: h.colorId,
    snippet: h.snippet,
    note: note,
  ),
);
