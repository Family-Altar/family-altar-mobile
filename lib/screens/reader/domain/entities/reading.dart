import 'package:equatable/equatable.dart';

class Reading extends Equatable {
  const Reading({
    required this.date,
    required this.scripture,
    required this.quote,
    required this.dailyReading,
  });
  final String date;
  final String scripture;
  final String quote;
  final String dailyReading;

  @override
  List<Object> get props => [date, scripture, quote, dailyReading];
}
