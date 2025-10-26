import 'package:family_altar/i18n/strings.g.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/home/home_screen.dart';
import 'package:family_altar/screens/missed_days/missed_days_screen.dart';
import 'package:family_altar/screens/reading/bloc/reading_bloc.dart';
import 'package:family_altar/screens/reading/bloc/reading_event.dart';
import 'package:family_altar/screens/reading/reading_screen.dart';
import 'package:family_altar/screens/settings/settings_screen.dart';
import 'package:family_altar/theme/bloc/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const String appTitle = 'The Family Altar - Tim Dodd';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TranslationProvider(child: const MyApp()));
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen(title: appTitle);
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
        GoRoute(
          path: 'book-selection',
          builder: (BuildContext context, GoRouterState state) {
            final title = state.uri.queryParameters['title'] ?? appTitle;
            return BookSelectionScreen(title: title);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/book/day-:dayId',
      builder: (BuildContext context, GoRouterState state) {
        // Extract dayId from URL parameters, default to '1' if not provided
        final dayId = state.pathParameters['dayId'] ?? '1';
        return DayReadingScreen(dayId: dayId);
      },
    ),
    GoRoute(
      path: '/missed-days/book-:volumeId',
      builder: (BuildContext context, GoRouterState state) {
        final volumeId = state.pathParameters['volumeId'] ?? '1';
        return MissedDaysScreen(volumeId: volumeId);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReadingBloc()..add(const ReadingLoadEvent()),
      child: ThemeProvider(
        router: _router,
        child: const SizedBox.shrink(),
      ),
    );
  }
}
