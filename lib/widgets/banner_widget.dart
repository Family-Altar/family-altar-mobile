import 'package:family_altar/theme/app_colors.dart'; // Assuming this imports Color constants
import 'package:flutter/material.dart';

class FamilyAltarBanner extends StatelessWidget {
  const FamilyAltarBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the background color based on the current theme mode
    const bgColor = AppColors.darkBackground;

    return Container(
      width: double.infinity,
      height: 220,
      color: bgColor,
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor, bgColor, Colors.transparent],
            stops: [0.0, 0.5, 1.0], // Fades out in the bottom half
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
