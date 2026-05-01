import 'package:family_altar/i18n/strings.g.dart';
import 'package:family_altar/navigation_service.dart';
import 'package:family_altar/notification_service.dart';
import 'package:family_altar/repository/reading_repository.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/foreword_preface/foreword_preface_screen.dart';
import 'package:family_altar/screens/home/home_screen.dart';
import 'package:family_altar/screens/missed_days/missed_days_screen.dart';
import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/screens/reader/reader_screen.dart';
import 'package:family_altar/screens/settings/settings_screen.dart';
import 'package:family_altar/storage/local_reading_storage.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

final GoRouter _router = GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: [routeObserver],
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen(title: 'The Family Altar');
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'book-selection',
          builder: (BuildContext context, GoRouterState state) {
            return const BookSelectionScreen(title: 'Book Selection');
          },
        ),
        GoRoute(
          path: 'reader',
          builder: (context, state) {
            final date = state.extra as DateTime?;
            return ReaderScreenProvider(date: date!);
          },
        ),
        GoRoute(
          path: 'foreword-preface',
          builder: (BuildContext context, GoRouterState state) {
            final section = state.extra as Section? ?? Section.foreword;
            return ForewordPrefaceScreenProvider(section: section);
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
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final localReadingStorage = LocalReadingStorage();
  final readingRepository = ReadingRepository(localReadingStorage);
  final readingBloc = ReadingBloc(readingRepository: readingRepository);
  await readingBloc.initializeFirstLaunchDate();
  readingBloc.add(LoadReadingEvent(date: DateTime.now()));

  runApp(
    TranslationProvider(
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: localReadingStorage),
          RepositoryProvider.value(value: readingRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: readingBloc),
            BlocProvider(
              create: (_) => ThemeBloc()..add(const ThemeInitializeEvent()),
            ),
          ],
          child: NotificationBootstrapper(child: MyApp(router: _router)),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp.router(
          routerConfig: router,
          title: 'The Family Altar',
          debugShowCheckedModeBanner: false,
          theme: themeState.lightTheme,
          darkTheme: themeState.darkTheme,
          themeMode: themeState.themeMode,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
        );
      },
    );
  }
}
