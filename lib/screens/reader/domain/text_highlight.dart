import 'package:equatable/equatable.dart';

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
    required this.start,
    required this.end,
    required this.colorId,
    this.snippet = '',
    this.note,
  });

  factory TextHighlight.fromJson(Map<String, dynamic> json) => TextHighlight(
    start: json['s'] as int,
    end: json['e'] as int,
    colorId: json['c'] as String,
    snippet: json['tx'] as String? ?? '',
    note: json['n'] as String?,
  );

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
    's': start,
    'e': end,
    'c': colorId,
    'tx': snippet,
    if (note != null) 'n': note,
  };

  @override
  List<Object?> get props => [start, end, colorId, snippet, note];
}
