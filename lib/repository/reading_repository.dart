import 'package:family_altar/storage/local_reading_storage.dart';

class ReadingRepository {
  ReadingRepository(this._localReadingStorage);

  final LocalReadingStorage _localReadingStorage;

  Future<String> fetchReading() async {
    print('in fetchReading from Repository');
    return await _localReadingStorage.fetchReading();
  }
}
