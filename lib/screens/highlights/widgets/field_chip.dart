import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';

class FieldChip extends StatelessWidget {
  const FieldChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.missedDaysBadgeBG,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppFonts.normal(
          context,
          size: FontSize.small,
        ).copyWith(color: context.missedDaysBadgeText, fontSize: 11),
      ),
    );
  }
}
