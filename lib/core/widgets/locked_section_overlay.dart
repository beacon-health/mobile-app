import 'dart:ui';

import 'package:flutter/material.dart';

/// Wraps a [child] card with a frosted-glass lock overlay that explains why
/// the section is unavailable (e.g. guest-only MVP features behind auth).
///
/// The underlying card is dimmed and blocks input; the centered badge shows a
/// lock icon and a short [message].
class LockedSectionOverlay extends StatelessWidget {
  const LockedSectionOverlay({
    required this.child,
    required this.message,
    this.horizontalPadding = 16,
    this.borderRadius = 12,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                child: SizedBox.expand(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
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
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
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
