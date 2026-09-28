import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/utils/phone_format.dart';
import 'package:beacon_app/core/widgets/drag_handle.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FacilityCard extends StatefulWidget {
  final Facility facility;
  final bool isExpanded;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleExpand;
  final Widget Function(String?) buildCategoryIcon;
  final Future<void> Function(String) onLaunchUrl;
  final bool showExpandButton;

  /// When false, the heart/favorite icon renders disabled and is not tappable.
  /// Used in guest mode where favorites require sign-in.
  final bool canFavorite;

  /// Opens the rating flow ("Already visited? Rate your experience"), shown as
  /// a Next Steps row when non-null. Callers gate guests to the sign-in
  /// prompt inside this callback.
  final VoidCallback? onRate;

  /// Opens the "submit corrections" flow ("Incorrect info?"), shown as a row
  /// beneath the rate row when non-null. Callers gate guests.
  final VoidCallback? onSubmitCorrection;

  /// Overrides the default list margin. The single-facility view passes
  /// [EdgeInsets.zero] so the card fills its rounded wrapper with no seams.
  final EdgeInsetsGeometry? margin;

  /// Overrides the Card's default shape (the single-facility view matches the
  /// wrapper's larger corner radius).
  final ShapeBorder? shape;

  /// Renders a drag handle at the top of the card, on the card's own
  /// background (used by the swipe-to-dismiss single-facility view).
  final bool showDragHandle;

  const FacilityCard({
    super.key,
    required this.facility,
    required this.isExpanded,
    required this.onToggleFavorite,
    required this.onToggleExpand,
    required this.buildCategoryIcon,
    required this.onLaunchUrl,
    this.showExpandButton = true,
    this.canFavorite = true,
    this.onRate,
    this.onSubmitCorrection,
    this.margin,
    this.shape,
    this.showDragHandle = false,
  });

  @override
  State<FacilityCard> createState() => _FacilityCardState();
}

class _FacilityCardState extends State<FacilityCard> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(FacilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.facility.id != widget.facility.id &&
        _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Collapsed rows preview services so users can judge relevance; expanded
  /// rows show "city, state" (the full text renders in the body).
  String get _subtitleText {
    final locationLine = '${widget.facility.city}, ${widget.facility.state}';
    if (widget.isExpanded) return locationLine;
    final description = widget.facility.description.trim();
    if (description.isNotEmpty) return description;
    final services = widget.facility.servicesSummary?.trim() ?? '';
    return services.isNotEmpty ? services : locationLine;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
      shape: widget.shape,
      clipBehavior: Clip.none,
      color: isDark ? null : AppColors.honeydew,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // GestureDetector, not InkWell — an InkWell ripple would fire across
          // the whole card.
          GestureDetector(
            onTap: widget.showExpandButton ? widget.onToggleExpand : null,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showDragHandle)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: DragHandle(),
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    right: AppSpacing.xxxl,
                  ),
                  child: ListTile(
                    leading: widget
                        .buildCategoryIcon(widget.facility.primaryCategory),
                    title: Text(
                      widget.facility.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: widget.isExpanded ? null : 1,
                      overflow: widget.isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _subtitleText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceMuted,
                      ),
                      maxLines: widget.isExpanded ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (widget.isExpanded) _buildFacilityDetails(widget.facility),
                if (!widget.isExpanded) const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          Positioned(
            top: -AppSpacing.xs,
            right: -AppSpacing.xs,
            child: IconButton(
              padding: const EdgeInsets.all(AppSpacing.sm),
              constraints: const BoxConstraints(),
              icon: Icon(
                widget.facility.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: !widget.canFavorite
                    ? theme.colorScheme.onSurface.withValues(
                        alpha: AppOpacity.disabled,
                      )
                    : (widget.facility.isFavorite ? AppColors.favorite : null),
                size: AppIconSize.md,
              ),
              // `null` onPressed renders the disabled state for guests.
              onPressed: widget.canFavorite ? widget.onToggleFavorite : null,
            ),
          ),
          if (widget.showExpandButton)
            Positioned(
              bottom: -AppSpacing.sm,
              right: -AppSpacing.xs,
              child: IconButton(
                padding: const EdgeInsets.all(AppSpacing.sm),
                constraints: const BoxConstraints(),
                icon: Icon(
                  widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: AppIconSize.md,
                ),
                onPressed: widget.onToggleExpand,
              ),
            ),
        ],
      ),
    );
  }

  bool _isOpen24_7(Facility facility) {
    return facility.hoursDisplay.toLowerCase().contains('24 hours') ||
        facility.hoursDisplay.toLowerCase().contains('24/7');
  }

  Widget _buildNextStepItem({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppIconSize.md, color: theme.colorScheme.tertiary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(value, style: theme.textTheme.labelMedium),
            ),
          ],
        ),
      ),
    );
  }

  void _openDirections() {
    final facility = widget.facility;
    final hasValidAddress = facility.address.isNotEmpty &&
        !facility.address.toLowerCase().contains('not available');
    final hasValidCity = facility.city.isNotEmpty;
    final hasValidState = facility.state.isNotEmpty;

    if (hasValidAddress && hasValidCity && hasValidState) {
      final fullAddress =
          '${facility.address}, ${facility.city}, ${facility.state}'.trim();
      // Chooser + remembered preference — iOS has no default-maps API.
      MapLauncherService.openDirections(context, address: fullAddress);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.cardAddressNotAvailable,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildFacilityDetails(Facility facility) {
    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (facility.description.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            Text(
              facility.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          ..._buildAtAGlanceSection(facility),
          ..._buildServicesSection(facility),
          const Divider(height: AppSpacing.md),
          _buildNextStepsAndHours(facility),
          // Full width so these don't wrap awkwardly in the narrow column.
          if (widget.onRate != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildActionLink(
              Icons.thumbs_up_down_outlined,
              AppLocalizations.of(context)!.cardRatePromptLead,
              AppLocalizations.of(context)!.cardRatePromptAction,
              widget.onRate,
            ),
          ],
          if (widget.onSubmitCorrection != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildActionLink(
              Icons.edit_note_outlined,
              AppLocalizations.of(context)!.cardCorrectionPromptLead,
              AppLocalizations.of(context)!.cardCorrectionPromptAction,
              widget.onSubmitCorrection,
            ),
          ],
        ],
      ),
    );

    if (!widget.showExpandButton) {
      return Flexible(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: content,
        ),
      );
    } else {
      return content;
    }
  }

  /// Full-width tappable "form" action (rate / submit corrections). The [lead]
  /// is bold in the default text color; only the [action] reads as a link
  /// (bittersweet, underlined) to flag the submittal route.
  Widget _buildActionLink(
    IconData icon,
    String lead,
    String action,
    VoidCallback? onTap,
  ) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.tertiary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.md, color: accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: lead,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: action,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent,
                        decoration: TextDecoration.underline,
                        decorationColor: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepsAndHours(Facility facility) {
    final is24_7 = _isOpen24_7(facility);
    final phone = facility.primaryPhone;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.cardNextSteps,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (widget.facility.website != null &&
                  widget.facility.website!.isNotEmpty)
                _buildNextStepItem(
                  icon: Icons.language,
                  value: AppLocalizations.of(context)!.cardVisitWebsite,
                  onTap: () => widget.onLaunchUrl(widget.facility.website!),
                )
              else
                _buildNextStepItem(
                  icon: Icons.language,
                  value: AppLocalizations.of(context)!.cardWebsiteNotAvailable,
                  onTap: () {},
                ),
              if (phone.isNotEmpty && phone != 'Phone not available')
                _buildNextStepItem(
                  icon: Icons.phone,
                  // Mixed source formats normalize to (xxx) xxx-xxxx.
                  value: formatPhoneForDisplay(phone),
                  onTap: () =>
                      widget.onLaunchUrl('tel:${dialablePhone(phone)}'),
                ),
              _buildNextStepItem(
                icon: Icons.directions,
                value: AppLocalizations.of(context)!.cardGetDirections,
                onTap: _openDirections,
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          color: theme.dividerColor,
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.cardHours,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (is24_7) ...[
                _buildDayHourRow('Open 24/7', ''),
              ] else ...[
                ...facility.hours.map(
                  (h) => _buildDayHourRow(
                    h.day,
                    h.opensAt != null && h.closesAt != null
                        ? '${_formatTime(h.opensAt!)} - ${_formatTime(h.closesAt!)}'
                        : '',
                  ),
                ),
                if (facility.hours.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.cardContactForHours,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurfaceMuted,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Services block (plain-language summary preferred, chips as fallback).
  /// Returns an empty list when the facility has no service data.
  List<Widget> _buildServicesSection(Facility facility) {
    final theme = Theme.of(context);
    final title = Text(
      AppLocalizations.of(context)!.cardServices,
      style: theme.textTheme.titleMedium,
    );

    if (facility.servicesSummary != null &&
        facility.servicesSummary!.isNotEmpty) {
      return [
        const Divider(height: AppSpacing.md),
        title,
        const SizedBox(height: AppSpacing.sm),
        Text(facility.servicesSummary!, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)!.cardServicesAiDisclaimer,
          style: _disclaimerStyle(theme),
        ),
        const SizedBox(height: AppSpacing.md),
      ];
    }
    if (facility.services.isNotEmpty) {
      return [
        const Divider(height: AppSpacing.md),
        title,
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final service in facility.services)
              TagChip(label: service, color: theme.colorScheme.tertiary),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ];
    }
    return const [];
  }

  /// Italic caption for AI-generated or free-text summaries.
  TextStyle? _disclaimerStyle(ThemeData theme) =>
      theme.textTheme.bodySmall?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurfaceMuted,
      );

  /// "At a Glance" eligibility chips + summary. Returns an empty list (no
  /// leading divider) when the facility has neither, so it can sit at the top
  /// of the details block without an orphan separator.
  List<Widget> _buildAtAGlanceSection(Facility facility) {
    final eligibilityChips = _buildEligibilityChips(facility);
    final hasSummary = facility.otherEligibilitySummary != null &&
        facility.otherEligibilitySummary!.isNotEmpty;
    if (eligibilityChips.isEmpty && !hasSummary) return const [];

    final theme = Theme.of(context);
    return [
      const Divider(height: AppSpacing.md),
      if (eligibilityChips.isNotEmpty) ...[
        Text(
          AppLocalizations.of(context)!.cardAtAGlance,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: eligibilityChips,
        ),
      ],
      if (hasSummary) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          facility.otherEligibilitySummary!,
          style: _disclaimerStyle(theme),
        ),
      ],
      const SizedBox(height: AppSpacing.xs),
    ];
  }

  List<Widget> _buildEligibilityChips(Facility facility) {
    final elig = facility.eligibility;
    if (elig == null) return [];

    final chips = <Widget>[];
    final color = Theme.of(context).colorScheme.primary;
    void addChip(String label, EligibilityValue value, IconData icon) {
      if (value == EligibilityValue.yes) {
        chips.add(TagChip(label: label, icon: icon, color: color));
      }
    }

    final l10n = AppLocalizations.of(context)!;
    addChip(l10n.chipWalkIns, elig.acceptsWalkins, Icons.directions_walk);
    addChip(l10n.chipFree, elig.freeServicesAvailable, Icons.money_off);
    addChip(l10n.chipTelehealth, elig.telehealthAvailable, Icons.videocam);
    addChip(l10n.chipAccessible, elig.wheelchairAccessible, Icons.accessible);
    addChip(l10n.chipSlidingScale, elig.slidingScaleAvailable, Icons.tune);
    addChip(
      l10n.chipOtherLanguages,
      elig.otherLanguages,
      Icons.translate,
    );
    return chips;
  }

  static String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute$period';
  }

  static String _formatDay(String day) {
    const dayMap = {
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };
    return dayMap[day.toLowerCase()] ?? day;
  }

  Widget _buildDayHourRow(String day, String hours) {
    final isClosed = hours.toLowerCase() == 'closed';
    final is24_7 = day.toLowerCase().contains('24/7');
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: isClosed ? theme.colorScheme.tertiary : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(is24_7 ? '' : _formatDay(day), style: style),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            is24_7 ? AppLocalizations.of(context)!.cardOpen247 : hours,
            style: style?.copyWith(
              fontWeight:
                  isClosed || is24_7 ? FontWeight.w700 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
