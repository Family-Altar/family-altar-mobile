import 'package:flutter/material.dart';
import 'package:family_altar/theme/app_colors.dart'; // Assuming this imports Color constants

class FamilyAltarBanner extends StatelessWidget {
  const FamilyAltarBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the background color based on the current theme mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.darkBackground;

    return Container(
      width: double.infinity,
      height: 220,
      // 3. CORRECTED: Use the calculated 'bgColor' instead of the non-existent context.backgroundColor
      color: bgColor,
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // 2. CORRECTED: Use 'bgColor' directly, removing the erroneous 'Color(bgColor)'
            colors: [bgColor, bgColor, Colors.transparent],
            stops: const [0.0, 0.5, 1.0], // Fades out in the bottom half
          ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
        },
        blendMode: BlendMode.dstIn,
        child: Image.asset(
          'assets/images/family_alter_book_cover.png',
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
