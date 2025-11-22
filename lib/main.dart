import 'package:family_altar/i18n/strings.g.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/home/home_screen.dart';
import 'package:family_altar/screens/missed_days/missed_days_screen.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/screens/reader/reader_screen.dart';
import 'package:family_altar/screens/settings/settings_screen.dart';
import 'package:family_altar/storage/local_reading_storage.dart';
import 'package:family_altar/theme/bloc/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const String appTitle = 'The Family Altar - Tim Dodd';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(title: appTitle),
      routes: <RouteBase>[
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'book-selection',
          builder: (context, state) {
            final title = state.uri.queryParameters['title'] ?? appTitle;
            return BookSelectionScreen(title: title);
          },
        ),
        GoRoute(
          path: 'reader',
          builder: (context, state) {
            final date = state.extra as DateTime?;
            return ReaderScreenProvider(date: date!);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/missed-days/book-:volumeId',
      builder: (context, state) {
        final volumeId = state.pathParameters['volumeId'] ?? '1';
        return MissedDaysScreen(volumeId: volumeId);
      },
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize your repositories
  final localReadingStorage = LocalReadingStorage();
  final readingRepository = ReadingRepository(localReadingStorage);

  runApp(
    TranslationProvider(
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: localReadingStorage),
          RepositoryProvider.value(value: readingRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            // Global ReadingBloc
            BlocProvider(
              create: (_) => ReadingBloc(readingRepository: readingRepository)
                ..add(LoadReadingEvent(date: DateTime.now())),
            ),
          ],
          child: ThemeProvider(
            router: _router,
          ), 
        ),
      ),
    ),
  );
}