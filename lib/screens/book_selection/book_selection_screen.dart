import 'package:flutter/material.dart';

import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';

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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
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
              style: AppFonts.normal(context, size: FontSize.medium),
            ),
          ],
        ),
      ),
    );
  }
}
