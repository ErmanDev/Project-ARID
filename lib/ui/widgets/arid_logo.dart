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
  const AridBrandTitle({
    super.key,
    this.label = 'A.R.I.D.',
    this.subtitle = 'Breeding-site monitoring',
  });

  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AridLogo(size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ).copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
