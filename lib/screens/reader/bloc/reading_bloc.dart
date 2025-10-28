import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/reader/domain/reading.dart';

part 'reading_event.dart';
part 'reading_state.dart';

class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  ReadingBloc({required ReadingRepository readingRepository})
    : super(ReadingInitial()) {
    on<LoadReadingEvent>((event, emit) async {
      print("from LoadReadingEvent function");
      final reading = await readingRepository.fetchReading();
      emit(ReadingLoaded(reading: reading));
    });
  }
}
