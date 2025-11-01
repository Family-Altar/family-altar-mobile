import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class LocalReadingStorage {
  Future<String> fetchReading({int? dayOfYear}) async {
    // Convert day of year to date and filename
    final date = _dayOfYearToDate(dayOfYear ?? _getCurrentDayOfYear());
    final fileName = _getFileName(date);
    
    final filePath = p.join(
      'assets/volume_I/daily_readings',
      fileName,
    );
    final fileContent = await rootBundle.loadString(filePath);
    return fileContent;
  }
  
  String _getFileName(DateTime date) {
    // e.g As Jer had "September_30.txt"
    final formatter = DateFormat('MMMM_d');
    return '${formatter.format(date)}.txt';
  }
  
  int _getCurrentDayOfYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year);
    final difference = now.difference(startOfYear).inDays;
    return difference + 1; // Days are 1-indexed
  }
  
  DateTime _dayOfYearToDate(int dayOfYear, {int? year}) {
    final targetYear = year ?? DateTime.now().year;
    final firstDayOfYear = DateTime(targetYear);
    return firstDayOfYear.add(Duration(days: dayOfYear - 1));
  }
}
