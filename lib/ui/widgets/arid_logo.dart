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

class AridBrandTitle extends StatelessWidget {
  const AridBrandTitle({super.key, this.label = 'A.R.I.D.'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AridLogo(size: 32),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
