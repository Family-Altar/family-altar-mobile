import 'package:equatable/equatable.dart';

class Page extends Equatable {
  const Page({required this.text});
  final String text;

  @override
  List<Object> get props => [text];
}
