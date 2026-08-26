import 'dart:math';

import 'package:equatable/equatable.dart';

final _idRandom = Random();

/// A short, unique-enough id for a newly created highlight — used to look
/// it up directly instead of matching on its content fields.
String generateHighlightId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '-${_idRandom.nextInt(1 << 32).toRadixString(36)}';

enum HighlightField {
  scripture,
  quote,
  title,
  dailyReading;

  String get storageKey => switch (this) {
    HighlightField.scripture => 'scripture',
    HighlightField.quote => 'quote',
    HighlightField.title => 'title',
    HighlightField.dailyReading => 'dailyReading',
  };

  String get displayLabel => switch (this) {
    HighlightField.scripture => 'Scripture',
    HighlightField.quote => 'Quote',
    HighlightField.title => 'Title',
    HighlightField.dailyReading => 'Daily Reading',
  };

  static HighlightField? fromStorageKey(String key) {
    for (final field in HighlightField.values) {
      if (field.storageKey == key) return field;
    }
    return null;
  }
}

class TextHighlight extends Equatable {
  const TextHighlight({
    required this.id,
    required this.start,
    required this.end,
    required this.colorId,
    this.snippet = '',
    this.note,
  });

  factory TextHighlight.fromJson(Map<String, dynamic> json) {
    final start = json['s'] as int;
    final end = json['e'] as int;
    final colorId = json['c'] as String;
    return TextHighlight(
      // Highlights saved before ids existed have none in storage — fall
      // back to a value derived from fields that are unique within a
      // single field's list, so lookups stay stable until the next edit
      // persists a real generated id in its place.
      id: json['id'] as String? ?? '$start-$end-$colorId',
      start: start,
      end: end,
      colorId: colorId,
      snippet: json['tx'] as String? ?? '',
      note: json['n'] as String?,
    );
  }

  /// Unique identifier used to look up this highlight directly, rather
  /// than matching on its content fields. See [generateHighlightId].
  final String id;

  /// Inclusive character offset into the field's highlightable text.
  final int start;

  /// Exclusive character offset into the field's highlightable text.
  final int end;

  final String colorId;

  /// The highlighted substring itself, captured at creation time.
  final String snippet;

  final String? note;

  bool overlaps(int otherStart, int otherEnd) =>
      start < otherEnd && otherStart < end;

  Map<String, dynamic> toJson() => {
    'id': id,
    's': start,
    'e': end,
    'c': colorId,
    'tx': snippet,
    if (note != null) 'n': note,
  };

  @override
  List<Object?> get props => [id, start, end, colorId, snippet, note];
}
