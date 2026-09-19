import 'package:equatable/equatable.dart';
enum ReadingStatus {
  completed,
  missed,
  upcoming,
}
class ReadingEntry extends Equatable {
  const ReadingEntry({
    required this.date,
    required this.status,
  });

  factory ReadingEntry.fromJson(Map<String, dynamic> json) {
    return ReadingEntry(
      date: DateTime.parse(json['date'] as String),
      status: ReadingStatus.values[json['status'] as int],
    );
  }

  final DateTime date;
  final ReadingStatus status;

  ReadingEntry copyWith({
    DateTime? date,
    ReadingStatus? status,
  }) {
    return ReadingEntry(
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  /// Convert to JSON for storage in SharedPreferences
  /// Serializes the entry into a Map that can be stored persistently.
  /// Date is stored as ISO 8601 string, status as integer index.
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'status': status.index, // Store enum as index (0, 1, 2)
    };
  }
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  DateTime get normalizedDate {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  List<Object?> get props => [date, status];
}

