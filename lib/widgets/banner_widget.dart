import 'package:flutter/material.dart';

class FamilyAltarBanner extends StatelessWidget {
  const FamilyAltarBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Removed margin/radius to match the full-width header look in the image
      // or kept minimal if preferred.
      height: 220, 
      color: const Color(0xFF1A1A1A),
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF1A1A1A), Colors.transparent],
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