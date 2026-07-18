@Tags(['local'])
library;

import 'dart:io';

import 'package:family_altar/models/volume.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/storage/local_reading_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads asset files directly from disk instead of via rootBundle so
/// these tests can run as plain unit tests without Flutter binding.
class _DiskReadingStorage extends LocalReadingStorage {
  @override
  Future<String> fetchReading({
    required DateTime date,
    Volume volume = Volume.one,
  }) async {
    final path = readingFilePath(date: date, volume: volume);
    return File(path).readAsString();
  }
}

void main() {
  final repository = ReadingRepository(_DiskReadingStorage());

  // Volume I has 366 files (includes Feb 29); use a leap year to hit it.
  // Volume II has 365 files (no Feb 29); use a non-leap year.
  const volumeDays = {Volume.one: 366, Volume.two: 365};
  const volumeYear = {Volume.one: 2024, Volume.two: 2023};

  for (final volume in Volume.values) {
    group(volume.displayTitle, () {
      final days = volumeDays[volume]!;
      final start = DateTime(volumeYear[volume]!, 1, 1);

      for (var i = 0; i < days; i++) {
        final date = start.add(Duration(days: i));

        test('${date.month}/${date.day}', () async {
          final reading = await repository.fetchReading(
            date: date,
            volume: volume,
          );

          expect(
            reading.date,
            isNotEmpty,
            reason:
                'Date header not found in '
                '${volume.displayTitle} ${date.month}/${date.day}',
          );
          expect(
            reading.scripture,
            isNotEmpty,
            reason:
                'Scripture reference not parsed in '
                '${volume.displayTitle} ${date.month}/${date.day}',
          );
          expect(
            reading.quote,
            isNotEmpty,
            reason:
                'Quote body is empty in '
                '${volume.displayTitle} ${date.month}/${date.day}',
          );
          expect(
            reading.title,
            isNotEmpty,
            reason:
                'Sermon title not found in '
                '${volume.displayTitle} ${date.month}/${date.day}',
          );
        });
      }
    });
  }
}
