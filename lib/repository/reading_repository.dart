import 'package:family_altar/models/volume.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/reader/domain/page.dart';
import 'package:family_altar/screens/reader/domain/reading.dart';
import 'package:family_altar/storage/local_reading_storage.dart';

class ReadingRepository {
  ReadingRepository(this._localReadingStorage);

  final LocalReadingStorage _localReadingStorage;

  Future<Reading> fetchReading({
    required DateTime date,
    Volume volume = Volume.one,
  }) async {
    final text = await _localReadingStorage.fetchReading(
      date: date,
      volume: volume,
    );

    final dateRegex = RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}',
    );
    final dateMatch = dateRegex.firstMatch(text);
    final dateText = dateMatch?.group(0) ?? '';
    final dateIndex = text.indexOf(dateText);

    final scriptureRegex = RegExp(
      r'\(('
      r'[1-3]?\s?[A-Z][a-z]+\.?'
      r'(?:\s+[A-Za-z][a-z]+\.?)*'
      r'\s+\d{1,3}:'
      r'\d{1,3}(?:[-–]\d{1,3})?'
      r'(?:\s*,\s*\d{1,3}(?:[-–]\d{1,3})?)*'
      r')\)',
    );
    final scriptureMatch = scriptureRegex.firstMatch(text);
    final scriptureEndIndex = scriptureMatch?.end ?? 0;

    final scripture =
        dateIndex >= 0 && dateText.isNotEmpty
            ? text
                .substring(dateIndex + dateText.length, scriptureEndIndex)
                .trim()
            : '';

    int sectionIndex;
    var dailyReading = '';

    if (volume == Volume.two) {
      // Match both singular and plural 'Parallel Scripture(s):'
      final match = RegExp('Parallel Scriptures?:').firstMatch(text);
      sectionIndex = match?.start ?? -1;
      if (match != null) {
        final start = match.end;
        final end = text.indexOf('\n', start);
        dailyReading =
            text.substring(start, end == -1 ? text.length : end).trim();
      }
    } else {
      const label = 'Daily Reading:';
      sectionIndex = text.indexOf(label);
      if (sectionIndex != -1) {
        final start = sectionIndex + label.length;
        final end = text.indexOf('\n', start);
        dailyReading =
            text.substring(start, end == -1 ? text.length : end).trim();
      }
    }

    final sermonTitleAndDateRegex = RegExp(r'\[\[\[.*\]\]\]');
    final sermonTitleAndDateMatch =
        sermonTitleAndDateRegex.allMatches(text).toList();
    final sermonTitleIndex =
        sermonTitleAndDateMatch.isNotEmpty
            ? sermonTitleAndDateMatch[0].start
            : -1;
    final sermonTitleAndDate =
        sermonTitleAndDateMatch.isNotEmpty
            ? (sermonTitleAndDateMatch[0]
                    .group(0)
                    ?.replaceAll('[', '')
                    .replaceAll(']', '') ??
                '')
            : '';

    final quoteEndIndex = sectionIndex != -1 ? sectionIndex : sermonTitleIndex;
    final quote =
        quoteEndIndex != -1
            ? text.substring(scriptureEndIndex, quoteEndIndex).trim()
            : '';

    return Reading(
      date: dateText,
      scripture: scripture,
      quote: quote,
      dailyReading:
          volume == Volume.one
              ? dailyReading.replaceAll('.', '')
              : dailyReading,
      title: sermonTitleAndDate,
    );
  }

  Future<Page> fetchPage({
    required Section sect,
    Volume volume = Volume.one,
  }) async {
    final text = await _localReadingStorage.fetchPage(
      sect: sect,
      volume: volume,
    );
    return Page(text: text);
  }
}
