import 'package:family_altar/screens/book_selection/book_selection_screen.dart';
import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.title, super.key});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48, 
        backgroundColor: context.appBarColor,
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        actions: [
          // Button to navigate to Book Selection screen
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => BookSelectionScreen(
                      title: widget.title,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[200],
                foregroundColor: context.isDarkMode
                    ? Colors.white
                    : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Volume I',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
          // Settings screen
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: Icon(
              Icons.settings,
              color: context.textColor,
            ),
            tooltip: 'Settings',
            iconSize: 20,
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Home Screen',
          style: AppFonts.bold(context, size: FontSize.large),
        ),
      ),
    );
  }
}
