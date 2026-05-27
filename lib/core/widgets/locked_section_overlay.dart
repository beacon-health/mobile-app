import 'dart:ui';

import 'package:flutter/material.dart';

/// Wraps a [child] card with a frosted-glass lock overlay that explains why
/// the section is unavailable (e.g. guest-only MVP features behind auth).
///
/// The underlying card is dimmed and blocks input. By default the centered
/// badge shows a lock icon and a short [message]; pass a [cta] widget (e.g.
/// an `AppleSignInButton`) to render an action below the badge instead.
class LockedSectionOverlay extends StatelessWidget {
  const LockedSectionOverlay({
    required this.child,
    required this.message,
    this.horizontalPadding = 16,
    this.borderRadius = 12,
    this.onTap,
    this.cta,
    super.key,
  });

  /// The card/section being locked.
  final Widget child;

  /// Short user-facing explanation shown inside the badge.
  final String message;

  /// Padding applied around the blurred overlay so it lines up with Card
  /// margins in the enclosing layout.
  final double horizontalPadding;

  /// Corner radius of the frosted clip rect. Should match the Card shape.
  final double borderRadius;

  /// Called when the user taps the lock overlay. When null AND [cta] is null,
  /// the overlay is purely decorative. Ignored when [cta] is supplied (the
  /// CTA takes over the action).
  final VoidCallback? onTap;

  /// Action button rendered under the lock badge (e.g. a sign-in button).
  /// When provided, the overlay is no longer tappable as a whole — the CTA
  /// is the sole interactive surface.
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 15,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );

    final overlayContent = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          if (cta != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: cta,
            ),
          ],
        ],
      ),
    );

    return Stack(
      children: [
        IgnorePointer(child: Opacity(opacity: 0.4, child: child)),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: cta != null
                    ? SizedBox.expand(child: overlayContent)
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          child: SizedBox.expand(child: overlayContent),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
