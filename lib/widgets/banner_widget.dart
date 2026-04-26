import 'package:family_altar/theme/app_colors.dart'; // Assuming this imports Color constants
import 'package:flutter/material.dart';

class FamilyAltarBanner extends StatelessWidget {
  const FamilyAltarBanner({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = AppColors.darkBackground;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final gradientStops = isLandscape
        ? const [0.0, 0.75, 1.0]
        : const [0.0, 0.5, 1.0];
    final imageFit = isLandscape ? BoxFit.contain : BoxFit.cover;

    return Container(
      width: double.infinity,
      color: bgColor,
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [bgColor, bgColor, Colors.transparent],
            stops: gradientStops,
          ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
        },
        blendMode: BlendMode.dstIn,
        child: Image.asset(
          'assets/images/family_alter_book_cover.png',
          width: double.infinity,
          fit: imageFit,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}
