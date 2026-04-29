import 'package:family_altar/theme/app_colors.dart'; // Assuming this imports Color constants
import 'package:flutter/material.dart';

class FamilyAltarBanner extends StatelessWidget {
  const FamilyAltarBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const bgColor = AppColors.darkBackground;
        // Use a single rule for all devices: width > height => landscape.
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        const portraitGradientStops = [0.0, 0.5, 1.0];
        final image = ClipRect(
          child: Image.asset(
            'assets/images/family_alter_book_cover.png',
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: isLandscape ? Alignment.center : Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
        );

        return Container(
          width: double.infinity,
          color: bgColor,
          child:
              isLandscape
                  ? image
                  : ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [bgColor, bgColor, Colors.transparent],
                        stops: portraitGradientStops,
                      ).createShader(
                        Rect.fromLTRB(0, 0, rect.width, rect.height),
                      );
                    },
                    blendMode: BlendMode.dstIn,
                    child: image,
                  ),
        );
      },
    );
  }
}
