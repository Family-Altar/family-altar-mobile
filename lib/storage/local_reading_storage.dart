import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class LocalReadingStorage {
  Future<String> fetchReading({required DateTime date}) async {
    // Convert day of year to date and filename
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
}
