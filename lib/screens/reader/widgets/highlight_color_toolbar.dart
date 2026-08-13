import 'package:family_altar/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HighlightColorToolbar extends StatelessWidget {
  const HighlightColorToolbar({
    required this.colorIds,
    required this.onColorSelected,
    this.selectedColorId,
    this.onRemove,
    this.onEditNote,
    super.key,
  });

  final List<String> colorIds;
  final String? selectedColorId;
  final ValueChanged<String> onColorSelected;
  final VoidCallback? onRemove;
  final VoidCallback? onEditNote;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.dialogBG,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        // Wrap (not Row) so this never hard-overflows when the popup's
        // available width is too narrow for every swatch + icon, e.g. the
        // tap-existing-highlight menu (swatches + note + remove) inside
        // showMenu's constrained width.
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final colorId in colorIds)
              _Swatch(
                colorId: colorId,
                isSelected: colorId == selectedColorId,
                onTap: () => onColorSelected(colorId),
              ),
            if (onEditNote != null)
              _ActionIcon(
                icon: Icons.edit_note,
                tooltip: 'Add note',
                onPressed: onEditNote!,
              ),
            if (onRemove != null)
              _ActionIcon(
                icon: Icons.format_color_reset,
                tooltip: 'Remove highlight',
                onPressed: onRemove!,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      icon: Icon(icon, color: context.textColor, size: 16),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colorId,
    required this.isSelected,
    required this.onTap,
  });

  final String colorId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.highlightColor(colorId);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: isSelected ? 4 : 0,
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
          ),
          child:
              isSelected
                  ? Icon(
                    Icons.check,
                    size: 14,
                    color: ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  )
                  : null,
        ),
      ),
    );
  }
}
