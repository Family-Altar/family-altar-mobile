import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class LocalReadingStorage {
  Future<String> fetchReading() async {
    String filePath = p.join(
      'assets/volume_I/daily_readings',
      'September_30.txt',
    );
    // ;/Users/jeremy/Development/family_altar/assets/volume_I/daily_readings/September_30.txt

    var fileContent = await rootBundle.loadString(
      'assets/volume_I/daily_readings/September_30.txt',
    );

    // File file = File(filePath);
    // var fileContent = await file.readAsString();
    print(fileContent);
    return fileContent;
  }
}
