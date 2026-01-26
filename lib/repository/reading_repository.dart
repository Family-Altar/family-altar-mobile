import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/reader/domain/page.dart';
import 'package:family_altar/screens/reader/domain/reading.dart';
import 'package:family_altar/storage/local_reading_storage.dart';
import 'package:flutter/gestures.dart';

class ReadingRepository {
  ReadingRepository(this._localReadingStorage);

  final LocalReadingStorage _localReadingStorage;

  Future<Reading> fetchReading({required DateTime date}) async {
    // Get raw text from storage
    final text = await _localReadingStorage.fetchReading(date: date);

    // --- Extract date ---
    final dateRegex = RegExp(r'([A-Za-z]+\s+\d+)');
    final dateMatch = dateRegex.allMatches(text).toList();
    final dateText = dateMatch[1].group(0) ?? '';
    final dateIndex = text.indexOf(dateText);

    print(dateText);

    // --- Extract scripture reference ---
    final scriptureRegex = RegExp(
      r'\(('
      r'[1-3]?\s?[A-Z][a-z]+\.?' // First word, optional period (Chron.)
      r'(?:\s+[A-Za-z][a-z]+\.?)*' // Additional words, optional period (Sol.)
      r'\s+\d{1,3}:' // Chapter number + colon
      r'\d{1,3}(?:[-–]\d{1,3})?' // Verse or range
      r'(?:\s*,\s*\d{1,3}(?:[-–]\d{1,3})?)*' // Optional more verses
      r')\)',
    );
    final scriptureMatch = scriptureRegex.firstMatch(text);
    final scriptureEndIndex = scriptureMatch?.end ?? 0;

    // --- Extract sections based on indices ---
    final scripture =
        text.substring(dateIndex + dateText.length, scriptureEndIndex).trim();
    const dailyReadingSearch = 'Daily Reading:';
    final dailyReadingIndex = text.indexOf(dailyReadingSearch);
    // final dailyReading =
    //     text.substring(dailyReadingIndex + dailyReadingSearch.length).trim();
    var dailyReading = '';
    if (dailyReadingIndex != -1) {
      final start = dailyReadingIndex + dailyReadingSearch.length;
      final end = text.indexOf('\n', start);
      dailyReading =
          text.substring(start, end == -1 ? text.length : end).trim();
    }

    final quote = text.substring(scriptureEndIndex, dailyReadingIndex).trim();

    final sermonTitleAndDateRegex = RegExp(r'\[\[\[.*\]\]\]');

    final sermonTitleAndDateMatch =
        sermonTitleAndDateRegex.allMatches(text).toList();
    final sermonTitleAndDate =
        sermonTitleAndDateMatch[0]
            .group(0)
            ?.replaceAll('[', '')
            .replaceAll(']', '') ??
        '';

    // --- Construct Reading object ---
    final reading = Reading(
      date: dateText,
      scripture: scripture,
      quote: quote,
      dailyReading: dailyReading,
      title: sermonTitleAndDate,
    );

    return reading;
  }

  Future<Page> fetchPage({required Section sect}) async {
    final text = await _localReadingStorage.fetchPage(sect: sect);
    return Page(text: text);
  }
}
