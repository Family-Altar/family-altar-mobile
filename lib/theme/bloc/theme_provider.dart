import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:family_altar/i18n/strings.g.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:family_altar/theme/bloc/theme_event.dart';
import 'package:family_altar/theme/bloc/theme_state.dart';

/// Theme provider widget that wraps the app and provides theme functionality
class ThemeProvider extends StatelessWidget {
  const ThemeProvider({
    super.key,
    required this.child,
    required this.router,
  });

  final Widget child;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeBloc()..add(const ThemeInitializeEvent()),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            theme: state.lightTheme,
            darkTheme: state.darkTheme,
            themeMode: state.themeMode,
            routerConfig: router,
            title: 'Family Altar',
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) {
              return child!;
            },
          );
        },
      ),
    );
  }
}

/// Extension to easily access theme bloc from context
extension ThemeBlocExtension on BuildContext {
  ThemeBloc get themeBloc => BlocProvider.of<ThemeBloc>(this);
}

/// Extension to easily access theme state from context
extension ThemeStateExtension on BuildContext {
  ThemeState get themeState => BlocProvider.of<ThemeBloc>(this).state;
}
