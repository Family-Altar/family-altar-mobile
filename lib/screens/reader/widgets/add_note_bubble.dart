import 'package:family_altar/theme/app_colors.dart';
import 'package:family_altar/theme/app_fonts.dart';
import 'package:flutter/material.dart';

/// Small pill button offered next to a highlight right after it's created,
/// so adding a note doesn't force the keyboard open immediately — it only
/// appears if this is tapped.
class AddNoteBubble extends StatelessWidget {
  const AddNoteBubble({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.dialogBG,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note, size: 16, color: context.textColor),
                const SizedBox(width: 4),
                Text(
                  'Add note',
                  style: AppFonts.normal(
                    context,
                    size: FontSize.small,
                  ).copyWith(color: context.textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
