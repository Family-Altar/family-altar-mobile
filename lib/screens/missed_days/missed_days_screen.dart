import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MissedDaysScreen extends StatelessWidget {
  const MissedDaysScreen({
    required this.volumeId,
    super.key,
  });

  final String volumeId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarColor,
        title: Text(
          'Book $volumeId',
          style: AppFonts.bold(context),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 80,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Book $volumeId',
                style: AppFonts.bold(context, size: FontSize.large),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Will put missed days stuffs here',
                style: AppFonts.normal(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

