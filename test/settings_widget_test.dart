import 'package:family_altar/screens/settings/settings_screen.dart';
import 'package:family_altar/theme/bloc/theme_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SettingsScreen displays theme options', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (context) => ThemeBloc(),
          child: const SettingsScreen(),
        ),
      ),
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
