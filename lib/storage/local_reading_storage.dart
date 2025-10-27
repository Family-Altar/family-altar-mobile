import 'dart:io';
import 'package:path/path.dart' as p;

class LocalReadingStorage {
  Future<String> fetchReading() async {
    String filePath = p.join(
      Directory.current.path,
      'assets/volume_I/daily_readings',
      'September_30.txt',
    );
    // ;/Users/jeremy/Development/family_altar/assets/volume_I/daily_readings/September_30.txt

    File file = File(filePath);
    var fileContent = await file.readAsString();
    print(fileContent);
    return fileContent;
  }
}
