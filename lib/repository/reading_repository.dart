import 'package:family_altar/screens/reader/domain/reading.dart';
import 'package:family_altar/storage/local_reading_storage.dart';

class ReadingRepository {
  ReadingRepository(this._localReadingStorage);

  final LocalReadingStorage _localReadingStorage;
  
  Future<Reading> fetchReading({int? dayOfYear}) async {
    // Get raw text from storage
    final text = await _localReadingStorage.fetchReading(dayOfYear: dayOfYear);

    // --- Extract date ---
    final dateRegex = RegExp(r'([A-Za-z]+\s+\d+)');
    final dateMatch = dateRegex.allMatches(text).toList();
    final dateText = dateMatch[1].group(0) ?? '';
    final dateIndex = text.indexOf(dateText);

    // --- Extract scripture reference ---
    final scriptureRegex = RegExp(
      r'\(([1-3]?\s?[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+\d{1,3}(?::\d{1,3}(?:[-–]\d{1,3})?)?)\)',
    );
    final scriptureMatch = scriptureRegex.firstMatch(text);
    final scriptureEndIndex = scriptureMatch?.end ?? 0;

    // --- Extract sections based on indices ---
    final scripture =
        text
            .substring(
              dateIndex + dateText.length,
              scriptureEndIndex,
            )
            .trim();
    const dailyReadingSearch = 'Daily Reading:';
    final dailyReadingIndex = text.indexOf(dailyReadingSearch);
    final dailyReading =
        text.substring(dailyReadingIndex + dailyReadingSearch.length).trim();

    final quote =
        text
            .substring(
              scriptureEndIndex,
              dailyReadingIndex,
            )
            .trim();

    // --- Construct Reading object ---
    final reading = Reading(
      date: dateText,
      scripture: scripture,
      quote: quote,
      dailyReading: dailyReading,
    );

    return reading;
  }
}
