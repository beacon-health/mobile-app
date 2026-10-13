import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The frame every onboarding step shares: the gradient, a way back, and how
/// far along the person is.
///
/// [children] scroll, so a step can't clip at the largest text sizes or under
/// the keyboard; [footer] stays pinned beneath them.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.children,
    this.footer,
    this.onBack,
  });

  /// Where to look (location or ZIP), then what you can provide. Choosing a
  /// ZIP is part of the first step: it only appears when GPS wasn't used, and
  /// a count that skipped from one to three would read as a missed screen.
  static const int totalSteps = 2;

  /// This step, counting from one.
  final int step;
  final List<Widget> children;
  final Widget? footer;

  /// Where "back" goes when this step is the bottom of the stack, so there is
  /// nothing to pop. Left null, the step pops if it can and otherwise shows
  /// no back button.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final onBack = this.onBack;
    final scaffold = _buildScaffold(context);
    if (onBack == null) return scaffold;
    // Android's back button follows the on-screen one.
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: scaffold,
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.onboarding(context)),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepHeader(step: step, onBack: onBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.onboardingGutter,
                    AppSpacing.lg,
                    AppSpacing.onboardingGutter,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.onboardingGutter,
                    AppSpacing.sm,
                    AppSpacing.onboardingGutter,
                    AppSpacing.lg,
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = AppLocalizations.of(context)!.onboardingStep(
      step,
      OnboardingScaffold.totalSteps,
    );
    // With nothing beneath it and nowhere named to go, the button would do
    // nothing — as when a guest signs in and onboarding restarts.
    final navigator = Navigator.of(context);
    final goBack = onBack ?? (navigator.canPop() ? navigator.maybePop : null);

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        top: AppSpacing.sm,
        end: AppSpacing.onboardingGutter,
      ),
      child: Row(
        children: [
          if (goBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: goBack,
            )
          else
            const SizedBox(width: AppSpacing.lg),
          const SizedBox(width: AppSpacing.sm),
          // One announcement ("Step 1 of 2") rather than a bar and a label.
          Expanded(
            child: Semantics(
              label: label,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        for (var i = 1; i <= OnboardingScaffold.totalSteps; i++)
                          Expanded(
                            child: Container(
                              height: AppSizes.handleHeight,
                              margin: const EdgeInsetsDirectional.only(
                                end: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: i <= step
                                    ? scheme.secondary
                                    : scheme.outlineVariant,
                                borderRadius: AppRadii.pillAll,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A step's title and the sentence under it.
class OnboardingHeading extends StatelessWidget {
  const OnboardingHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
