import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookSelectionScreen extends StatelessWidget {
  const BookSelectionScreen({required this.title, super.key});
  
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48, 
        backgroundColor: context.appBarColor,
        title: Text(
          title,
           style: AppFonts.bold(context, size: FontSize.large),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
            size: AppIcons.getIconSize(IconSize.medium),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Book Selection Page',
              style: AppFonts.bold(context, size: FontSize.large),
            ),
            const SizedBox(height: 20),
            Text(
              'This page will contain book selection options',
              style: AppFonts.normal(context),
            ),
          ],
        ),
      ),
    );
  }
}
