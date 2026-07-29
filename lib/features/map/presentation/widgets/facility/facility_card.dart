import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/utils/phone_format.dart';
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

  /// Collapsed rows preview what the facility offers so users can judge
  /// relevance before opening; expanded rows show "city, state" here (the full
  /// text renders in the body). Description is preferred but currently null
  /// across the dataset, so the services summary is the working preview.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: widget.shape,
      clipBehavior: Clip.none,
      color: isDark ? null : AppTheme.honeydew,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The whole card toggles expansion; the chevron is just an
          // affordance. GestureDetector rather than InkWell so the tap doesn't
          // fire a circular ripple across the card.
          GestureDetector(
            onTap: widget.showExpandButton ? widget.onToggleExpand : null,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showDragHandle)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    right: 32.0,
                  ),
                  child: ListTile(
                    leading: widget
                        .buildCategoryIcon(widget.facility.primaryCategory),
                    title: Text(
                      widget.facility.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: widget.isExpanded ? null : 1,
                      overflow: widget.isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _subtitleText,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      maxLines: widget.isExpanded ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (widget.isExpanded) _buildFacilityDetails(widget.facility),
                if (!widget.isExpanded) const SizedBox(height: 8),
              ],
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              icon: Icon(
                widget.facility.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: !widget.canFavorite
                    ? Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3)
                    : (widget.facility.isFavorite ? Colors.red : null),
                size: 20,
              ),
              // `null` onPressed renders the disabled state for guests.
              onPressed: widget.canFavorite ? widget.onToggleFavorite : null,
            ),
          ),
          if (widget.showExpandButton)
            Positioned(
              bottom: -4,
              right: -2,
              child: IconButton(
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                icon: Icon(
                  widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
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
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.bittersweet,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (facility.description.isNotEmpty) ...[
            const Divider(height: 12),
            Text(
              facility.description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
          ],
          ..._buildAtAGlanceSection(facility),
          ..._buildServicesSection(facility),
          const Divider(height: 12),
          _buildNextStepsAndHours(facility),
          // Full width so these don't wrap awkwardly in the narrow column.
          if (widget.onRate != null) ...[
            const SizedBox(height: 6),
            _buildActionLink(
              Icons.thumbs_up_down_outlined,
              AppLocalizations.of(context)!.cardRatePromptLead,
              AppLocalizations.of(context)!.cardRatePromptAction,
              widget.onRate,
            ),
          ],
          if (widget.onSubmitCorrection != null) ...[
            const SizedBox(height: 10),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.bittersweet),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: lead,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    TextSpan(
                      text: action,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.bittersweet,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.bittersweet,
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
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
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.cardHours,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
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
    final title = Text(
      AppLocalizations.of(context)!.cardServices,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );

    if (facility.servicesSummary != null &&
        facility.servicesSummary!.isNotEmpty) {
      return [
        const Divider(height: 12),
        title,
        const SizedBox(height: 8),
        Text(
          facility.servicesSummary!,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 12),
      ];
    }
    if (facility.services.isNotEmpty) {
      return [
        const Divider(height: 12),
        title,
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: facility.services.map((service) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.bittersweet.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.bittersweet.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                service,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.bittersweet,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ];
    }
    return const [];
  }

  /// "At a Glance" eligibility chips + summary. Returns an empty list (no
  /// leading divider) when the facility has neither, so it can sit at the top
  /// of the details block without an orphan separator.
  List<Widget> _buildAtAGlanceSection(Facility facility) {
    final eligibilityChips = _buildEligibilityChips(facility);
    final hasSummary = facility.otherEligibilitySummary != null &&
        facility.otherEligibilitySummary!.isNotEmpty;
    if (eligibilityChips.isEmpty && !hasSummary) return const [];

    return [
      const Divider(height: 12),
      if (eligibilityChips.isNotEmpty) ...[
        Text(
          AppLocalizations.of(context)!.cardAtAGlance,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: eligibilityChips,
        ),
      ],
      if (hasSummary) ...[
        const SizedBox(height: 12),
        Text(
          facility.otherEligibilitySummary!,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
      const SizedBox(height: 4),
    ];
  }

  List<Widget> _buildEligibilityChips(Facility facility) {
    final elig = facility.eligibility;
    if (elig == null) return [];

    final chips = <Widget>[];
    void addChip(String label, EligibilityValue value, IconData icon) {
      if (value == EligibilityValue.yes) {
        chips.add(_eligChip(label, icon, AppTheme.resedaGreen));
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

  Widget _eligChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
    final defaultColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              is24_7 ? '' : _formatDay(day),
              style: TextStyle(
                fontSize: 11,
                color: isClosed ? AppTheme.bittersweet : defaultColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            is24_7 ? AppLocalizations.of(context)!.cardOpen247 : hours,
            style: TextStyle(
              fontSize: 11,
              color: isClosed ? AppTheme.bittersweet : defaultColor,
              fontWeight:
                  isClosed || is24_7 ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
