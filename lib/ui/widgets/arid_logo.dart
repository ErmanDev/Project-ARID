import 'package:flutter/material.dart';

class AridLogo extends StatelessWidget {
  const AridLogo({super.key, this.size = 32});

  static const assetPath = 'assets/branding/arid_logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'A.R.I.D.',
    );
  }
}
