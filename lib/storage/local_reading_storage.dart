import 'package:family_altar/models/volume.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class LocalReadingStorage {
  Future<String> fetchReading({
    required DateTime date,
    Volume volume = Volume.one,
  }) async {
    final path = readingFilePath(date: date, volume: volume);
    if (volume == Volume.three) {
      final data = await rootBundle.load(path);
      return _decodeUtf16Le(data.buffer.asUint8List());
    }
    return rootBundle.loadString(path);
  }

  String _decodeUtf16Le(Uint8List bytes) {
    final start =
        (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) ? 2 : 0;
    final codeUnits = <int>[];
    for (var i = start; i + 1 < bytes.length; i += 2) {
      codeUnits.add(bytes[i] | (bytes[i + 1] << 8));
    }
    return String.fromCharCodes(codeUnits);
  }

  String readingFilePath({required DateTime date, required Volume volume}) {
    final fileName = _getFileName(date);
    // Asset bundle keys are always POSIX-style, regardless of host OS —
    // `p.join` would emit backslashes on a Windows host, which the asset
    // bundle wouldn't recognize.
    return p.posix.join('${volume.assetBasePath}/daily_readings', fileName);
  }

  String _getFileName(DateTime date) {
    final formatter = DateFormat('MMMM_d');
    return '${formatter.format(date)}.txt';
  }

  Future<String> fetchPage({
    required Section sect,
    Volume volume = Volume.one,
  }) async {
    switch (sect) {
      case Section.foreword:
        return _loadStaticPage('Foreword.txt', volume);
      case Section.preface:
        final fileName = volume == Volume.three ? 'preface.txt' : 'Preface.txt';
        return _loadStaticPage(fileName, volume);
      case Section.dailyReading:
        final fileName = _getFileName(DateTime.now());
        final filePath = p.posix.join(
          '${volume.assetBasePath}/daily_readings',
          fileName,
        );
        if (volume == Volume.three) {
          final data = await rootBundle.load(filePath);
          return _decodeUtf16Le(data.buffer.asUint8List());
        }
        return rootBundle.loadString(filePath);
    }
  }

  Future<String> _loadStaticPage(String fileName, Volume volume) async {
    final filePath = p.posix.join('${volume.assetBasePath}/', fileName);
    return rootBundle.loadString(filePath);
  }
}
