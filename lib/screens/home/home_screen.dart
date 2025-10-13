import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
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
          style: AppFonts.bold(context),
        ),
        actions: [
          // Button to navigate to Book Selection screen
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {
                context.push('/book-selection?title=${Uri.encodeComponent(widget.title)}');
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
      body: Center(
        child: Text(
          'Home Screen',
          style: AppFonts.bold(context, size: FontSize.large),
        ),
      ),
    );
  }
}
