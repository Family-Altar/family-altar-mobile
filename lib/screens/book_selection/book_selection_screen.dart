import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookSelectionScreen extends StatelessWidget {
  const BookSelectionScreen({required this.title, super.key});

  static const _bookConfigs = [
    BookItemData(
      imagePath: 'assets/images/FamilyAltarVolumeICover.jpg',
      lines: const ['Volume I', 'Foreword', 'Preface'],
    ),
    BookItemData(
      imagePath: 'assets/images/FamilyAltarVolumeICover.jpg',
      lines: const ['Volume II', 'Foreword', 'Preface'],
    ),
    BookItemData(
      imagePath: 'assets/images/FamilyAltarVolumeICover.jpg',
      lines: const ['Volume III', 'Foreword', 'Preface'],
    ),
  ];

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: context.appBarColor,
        title: Text(title, style: AppFonts.bold(context, size: FontSize.large)),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: context.textColor,
            size: AppIcons.getIconSize(IconSize.medium),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bookConfigs.length,
        itemBuilder: (_, index) => BookItem(data: _bookConfigs[index]),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
      ),
    );
  }
}

class BookItem extends StatelessWidget {
  const BookItem({required this.data, super.key});

  final BookItemData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(data.imagePath, width: 120),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < data.lines.length; i++)
                Text(
                  data.lines[i],
                  style: AppFonts.italics(
                    context,
                    size: i == 0 ? FontSize.xlarge : FontSize.large,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class BookItemData {
  const BookItemData({required this.imagePath, required this.lines});

  final String imagePath;
  final List<String> lines;
}
