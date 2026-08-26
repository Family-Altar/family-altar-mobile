import 'package:family_altar/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ColorFilterDot extends StatelessWidget {
  const ColorFilterDot({
    required this.colorId,
    required this.isSelected,
    required this.onTap,
    super.key,
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
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? context.textColor : Colors.transparent,
            width: 2,
          ),
        ),
        child:
            isSelected
                ? Icon(
                  Icons.check,
                  size: 14,
                  color:
                      ThemeData.estimateBrightnessForColor(color) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                )
                : null,
      ),
    );
  }
}
