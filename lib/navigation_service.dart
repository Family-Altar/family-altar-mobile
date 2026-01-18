import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

void navigateToTodayReading() {
  final context = rootNavigatorKey.currentContext;
  if (context == null) {
    return;
  }
  GoRouter.of(context).go('/reader', extra: DateTime.now());
}
