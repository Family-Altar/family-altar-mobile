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
    final fileName = _getFileName(date);
    final filePath = p.join(
      '${volume.assetBasePath}/daily_readings',
      fileName,
    );
    return rootBundle.loadString(filePath);
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
        return _loadStaticPage('Preface.txt', volume);
      case Section.dailyReading:
        final fileName = _getFileName(DateTime.now());
        final filePath = p.join(
          '${volume.assetBasePath}/daily_readings',
          fileName,
        );
        return rootBundle.loadString(filePath);
    }
  }

  Future<String> _loadStaticPage(String fileName, Volume volume) async {
    final filePath = p.join('${volume.assetBasePath}/', fileName);
    return rootBundle.loadString(filePath);
  }
}
