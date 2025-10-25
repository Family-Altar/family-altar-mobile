import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: context.appBarColor,
        title: Text('test', style: AppFonts.bold(context)),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
            size: AppIcons.getIconSize(IconSize.medium),
          ),
        ),
      ),
      body: Scrollbar(
        child: Center(
          child: Column(
            children: [
              Text(
                'scripture',
                style: AppFonts.italics(context),
              ),
              Text(
                'Quote',
                style: AppFonts.normal(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_circle_left_outlined),
              onPressed: () {
                // TODO: navigate to previous day
              },
            ),
            const Text(
              'Day 8 of 366',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_circle_right_outlined),
              onPressed: () {
                // TODO: navigate to next day
              },
            ),
          ],
        ),
      ),
    );
  }
}
