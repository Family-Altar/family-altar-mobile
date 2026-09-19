import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:family_altar/utils/utilities.dart';
import 'package:flutter/material.dart';

class DateRangeChip extends StatelessWidget {
  const DateRangeChip({
    required this.dateRange,
    required this.onTap,
    this.onClear,
    super.key,
  });

  final DateTimeRange? dateRange;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isActive = dateRange != null;
    final label =
        isActive
            ? '${formatDateTypeToDDMM(dateRange!.start)} – '
                '${formatDateTypeToDDMM(dateRange!.end)}'
            : 'Date range';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? context.accent.withValues(alpha: 0.12)
                  : context.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 16, color: context.textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.normal(
                context,
                size: FontSize.small,
              ).copyWith(fontWeight: isActive ? FontWeight.bold : null),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: context.textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
