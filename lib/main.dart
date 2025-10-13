import 'package:family_altar/i18n/strings.g.dart';
import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/screens/home/home_screen.dart';
import 'package:family_altar/screens/settings/settings_screen.dart';
import 'package:family_altar/theme/bloc/theme_provider.dart';
import 'package:flutter/material.dart';
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
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      router: _router,
      child: const SizedBox.shrink(),
    );
  }
}
