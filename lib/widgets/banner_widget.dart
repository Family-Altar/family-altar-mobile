import 'package:family_altar/theme/app_colors.dart'; // Assuming this imports Color constants
import 'package:flutter/material.dart';

class FamilyAltarBanner extends StatelessWidget {
  const FamilyAltarBanner({super.key});

  // Places [imageFocalY] (0=top, 1=bottom of image) at [widgetTargetY]
  // (0=top, 1=bottom of widget) when using BoxFit.cover.
  // [imageAspectRatio] = imageWidth / imageHeight.
  static Alignment _focalAlignment({
    required double imageFocalY,
    required double widgetTargetY,
    required double imageAspectRatio,
    required double widgetWidth,
    required double widgetHeight,
  }) {
    final scaledH = widgetWidth / imageAspectRatio;
    final overflow = scaledH - widgetHeight;
    if (overflow <= 0) return Alignment(0, imageFocalY * 2 - 1);
    final cropTop = imageFocalY * scaledH - widgetTargetY * widgetHeight;
    return Alignment(0, (2 * cropTop / overflow - 1).clamp(-1.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const bgColor = AppColors.darkBackground;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        const portraitGradientStops = [0.0, 0.5, 1.0];

        // Focal point tuning:
        //   imageFocalY  — where in the image the subject is (0=top, 1=bottom)
        //   widgetTargetY — where in the visible banner to place it
        //   (0=top, 1=bottom)
        //   imageAspectRatio — imageWidth / imageHeight (check your asset file)
        final portraitAlignment = _focalAlignment(
          imageFocalY: 0.6,
          widgetTargetY: 0.85,
          imageAspectRatio: 3 / 4,
          widgetWidth: constraints.maxWidth,
          widgetHeight: constraints.maxHeight,
        );

        final image = ClipRect(
          child: Image.asset(
            'assets/images/family_alter_book_cover.png',
            width: double.infinity,
            fit: BoxFit.cover,
            alignment: isLandscape ? Alignment.center : portraitAlignment,
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
