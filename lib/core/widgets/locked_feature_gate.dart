import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/widgets/sign_in_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wraps [child] so it is non-interactive for guest users.
///
/// When the current user is a guest, pointer events are absorbed and any tap
/// opens [showSignInPromptDialog]. When signed in, [child] is returned
/// unchanged with no overhead.
///
/// Requires [GuestModeService] in the widget tree (provided at app root).
///
/// Usage:
/// ```dart
/// LockedFeatureGate(
///   child: EligibilityFilterChip(...),
/// )
/// ```
class LockedFeatureGate extends StatelessWidget {
  const LockedFeatureGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isGuest = context.watch<GuestModeService>().isGuest;
    if (!isGuest) return child;

    return Stack(
      children: [
        IgnorePointer(child: child),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showSignInPromptDialog(context),
          ),
        ),
      ],
    );
  }
}
