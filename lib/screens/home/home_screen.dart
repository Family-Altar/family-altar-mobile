import 'package:family_altar/screens/reader/bloc/reading_bloc.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:family_altar/widgets/banner_widget.dart';
import 'package:family_altar/widgets/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.title, super.key});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<DateTime> _getLastReadingOrToday() async {
    // Try to get the last accessed day from storage
    final lastAccessed = await ReadingBloc.getLastAccessedDay();
    if (lastAccessed != null) {
      return lastAccessed;
    }
    // If no last accessed day, return today
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: context.appBarColor,
        title: Text(
          widget.title,
          style: AppFonts.bold(context),
        ),
        actions: [
          // Button to navigate to Book Selection screen
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  '/book-selection?title=${Uri.encodeComponent(widget.title)}',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                foregroundColor:
                    context.isDarkMode ? Colors.white : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Volume I',
                style: AppFonts.normal(context, size: FontSize.small),
              ),
            ),
          ),
          // Settings screen
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(
              Icons.settings,
              color: context.textColor,
            ),
            tooltip: 'Settings',
            iconSize: AppIcons.getIconSize(IconSize.medium),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Banner
            const FamilyAltarBanner(),
            // Continue reading button
            // Navigates to last accessed or today's reading
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Get the date to navigate to (last accessed or today)
                  final date = await _getLastReadingOrToday();
                  // Convert date to day-of-year for reading navigation
                  if (context.mounted) {
                    // valid context, navigate
                    await context.push('/reader', extra: date);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryButtonBGColor,
                  foregroundColor:
                      context.isDarkMode ? Colors.white : Colors.black,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue where you left off',
                  style: AppFonts.bold(context).copyWith(
                    // in the design i put white should i stick to white on
                    // light mode ? ask Jer
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Calendar widget
            const FamilyAltarCalendar(),
          ],
        ),
      ),
    );
  }
}
