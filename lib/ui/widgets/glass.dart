import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Saturation ×1.3 with Rec. 709 luminance weights, so colors behind the glass
// stay lively instead of washing out.
const _saturate = ui.ColorFilter.matrix(<double>[
  1.2362, -0.2146, -0.0217, 0, 0, //
  -0.0638, 1.0854, -0.0217, 0, 0, //
  -0.0638, -0.2146, 1.2783, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// The functional layer's material: a blurred, lightly saturated translucent
/// surface for floating bars and map controls only — never for content.
///
/// Flutter exposes no Reduce Transparency signal, so Increase Contrast
/// (`MediaQuery.highContrast`) falls back to an opaque, outlined surface.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.floating = false,
    this.showEdge = true,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Adds a soft shadow so the surface lifts off busy content such as a map.
  final bool floating;
  final bool showEdge;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final opaque = p.highContrast || MediaQuery.highContrastOf(context);
    final shadow = floating
        ? [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.4
                    : 0.12,
              ),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
        : null;

    if (opaque) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: borderRadius,
          border: Border.all(color: p.separator),
          boxShadow: shadow,
        ),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.compose(
            outer: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            inner: _saturate,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.glassFill,
              borderRadius: borderRadius,
              border: showEdge ? Border.all(color: p.glassEdge) : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A round glass button for controls that float over the map.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.busy = false,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return GlassSurface(
      floating: true,
      borderRadius: BorderRadius.circular(24),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        isSelected: selected,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: selected ? p.accent : p.ink,
        ),
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Icon(icon),
      ),
    );
  }
}
