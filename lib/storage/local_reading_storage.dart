import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class LocalReadingStorage {
  Future<String> fetchReading({required DateTime date}) async {
    // Convert day of year to date and filename
    final fileName = _getFileName(date);

    final filePath = p.join('assets/volume_I/daily_readings', fileName);
    print(filePath);
    final fileContent = await rootBundle.loadString(filePath);
    return fileContent;
  }

  String _getFileName(DateTime date) {
    // e.g As Jer had "September_30.txt"
    final formatter = DateFormat('MMMM_d');
    return '${formatter.format(date)}.txt';
  }

  Future<String> fetchPage({required Section sect}) async {
    switch (sect) {
      case Section.foreword:
        return _loadStaticPage('Foreword.txt');
      case Section.preface:
        return _loadStaticPage('Preface.txt');
      case Section.dailyReading:
        final fileName = _getFileName(DateTime.now());
        final filePath = p.join('assets/volume_I/daily_readings', fileName);
        print(filePath);
        return rootBundle.loadString(filePath);
    }
  }

  Future<String> _loadStaticPage(String fileName) async {
    final filePath = p.join('assets/volume_I/', fileName);
    print(filePath);
    return rootBundle.loadString(filePath);
  }
}
