import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/utils/phone_format.dart';
import 'package:beacon_app/core/widgets/dashed_vertical_divider.dart';
import 'package:beacon_app/core/widgets/drag_handle.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One facility: a row in the map's list, which expands in place, and the
/// whole of the sheet a tapped pin opens. Both are the same card on the same
/// surface, so a facility looks the same however it was reached.
class FacilityCard extends StatefulWidget {
  final Facility facility;
  final bool isExpanded;

  /// The heart was tapped. Callers decide what that means for a guest (the
  /// sign-in prompt); the button itself is always live.
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleExpand;
  final Widget Function(String?) buildCategoryIcon;
  final Future<void> Function(String) onLaunchUrl;
  final bool showExpandButton;

  /// Opens the rating flow ("Already visited? Rate your experience"), shown
  /// beneath the details when non-null. Callers gate guests to the sign-in
  /// prompt inside this callback.
  final VoidCallback? onRate;

  /// Opens the "submit corrections" flow ("Incorrect info?"), shown as a row
  /// beneath the rate row when non-null. Callers gate guests.
  final VoidCallback? onSubmitCorrection;

  /// Overrides the default list margin. The facility sheet passes
  /// [EdgeInsets.zero] so the card fills it edge to edge.
  final EdgeInsetsGeometry? margin;

  /// Overrides the Card's default shape (the facility sheet rounds only its
  /// top corners).
  final ShapeBorder? shape;

  /// Renders a drag handle at the top of the card, on the card's own
  /// background (used by the swipe-to-dismiss facility sheet).
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
    this.onRate,
    this.onSubmitCorrection,
    this.margin,
    this.shape,
    this.showDragHandle = false,
  });

  /// Whether the app says "Address copied" itself. Android (13 and later)
  /// already shows what was copied, and a second message would repeat it;
  /// iOS shows nothing.
  static bool confirmsCopy(TargetPlatform platform) =>
      platform != TargetPlatform.android;
  @override
  State<FacilityCard> createState() => _FacilityCardState();
}

class _FacilityCardState extends State<FacilityCard> {
  /// Least height of the three actions under the name.
  static const double _actionMinHeight = 64;

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

  /// "Chicago, IL • Community Health Center": where it is and what kind of
  /// place, in one short line. The street address waits in the details,
  /// beside Directions, so the list stays light.
  String get _placeLine {
    final facility = widget.facility;
    final place = [facility.city, facility.state]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');
    final category = facility.categoryDetail?.trim() ?? '';
    if (place.isEmpty) return category;
    if (category.isEmpty) return place;
    return AppLocalizations.of(context)!.cardPlaceAndCategory(place, category);
  }

  /// Name, then where and what kind of place. Collapsed, the name is one
  /// line ("Public Health Institute Of…"), so every row is the same height;
  /// expanded, and in the sheet, it shows in full.
  Widget _buildTitleBlock(ThemeData theme) {
    final placeLine = _placeLine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.facility.name,
          style: widget.showExpandButton
              ? theme.textTheme.titleSmall
              : theme.textTheme.titleMedium,
          maxLines: widget.isExpanded ? null : 1,
          overflow: widget.isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (placeLine.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          // Regular and muted, so it reads as the name's caption rather than
          // a second title.
          Text(
            placeLine,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: widget.isExpanded ? null : 2,
            overflow: widget.isExpanded ? null : TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildFavoriteButton(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final facility = widget.facility;
    return IconButton(
      // Named for the facility, so a screen reader or Voice Control user can
      // tell one heart from the next.
      tooltip: facility.isFavorite
          ? l10n.cardUnsave(facility.name)
          : l10n.cardSave(facility.name),
      icon: Icon(
        facility.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: facility.isFavorite
            ? AppColors.favorite
            : theme.colorScheme.onSurfaceVariant,
      ),
      onPressed: widget.onToggleFavorite,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final expandable = widget.showExpandButton;

    final header = Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        // Under the handle's band, which already leaves room above.
        // Under the handle's band, which already leaves room above; a list
        // row gets more air than the sheet's header.
        top: widget.showDragHandle
            ? 0
            : expandable
                ? AppSpacing.lg
                : AppSpacing.md,
        // In a list row, room for the heart and the arrow under it.
        end: expandable ? AppSizes.minTouchTarget : 0,
        bottom: expandable ? AppSpacing.lg : AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.buildCategoryIcon(widget.facility.primaryCategory),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildTitleBlock(theme)),
          if (!expandable) _buildFavoriteButton(theme),
        ],
      ),
    );

    return Card(
      margin: widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
      shape: widget.shape,
      clipBehavior: Clip.none,
      color: theme.colorScheme.facilityCard,
      child:
          expandable ? _buildListRow(theme, l10n, header) : _buildSheet(header),
    );
  }

  /// A row of the list: the header, with the details growing beneath it when
  /// expanded. The whole row shows and hides them, so the arrow is only a cue
  /// and needs no target of its own. It sits at the header's bottom-right,
  /// tucked under the heart in a one-line row and below a longer name.
  Widget _buildListRow(ThemeData theme, AppLocalizations l10n, Widget header) {
    return Stack(
      children: [
        // One button to a screen reader: "Show details" or "Hide details".
        Semantics(
          container: true,
          button: true,
          expanded: widget.isExpanded,
          onTapHint:
              widget.isExpanded ? l10n.cardHideDetails : l10n.cardShowDetails,
          // GestureDetector, not InkWell — an InkWell ripple would fire
          // across the whole card.
          child: GestureDetector(
            onTap: widget.onToggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    // Tall enough for the heart and the arrow under it.
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: _arrowTop + AppIconSize.lg + AppSpacing.xs,
                      ),
                      child: header,
                    ),
                    // Taps fall through to the row.
                    PositionedDirectional(
                      bottom: AppSpacing.xs,
                      end: (AppSizes.minTouchTarget - AppIconSize.lg) / 2,
                      child: ExcludeSemantics(
                        child: Icon(
                          widget.isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: AppIconSize.lg,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.isExpanded) _buildFacilityDetails(widget.facility),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: _buildFavoriteButton(theme),
        ),
      ],
    );
  }

  /// Where the arrow starts in a one-line row: just inside the bottom of the
  /// heart's target, below its icon.
  static const double _arrowTop = AppSizes.minTouchTarget - AppSpacing.sm;

  /// The whole of the facility sheet: a fixed handle, and everything else —
  /// name included — scrolling beneath it, so a long name at a large text
  /// size can't push the details out of reach.
  Widget _buildSheet(Widget header) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Everything below scrolls, so the scroll view takes drags there:
        // this band, a full touch target tall and the sheet's width, is
        // where a swipe moves the sheet.
        if (widget.showDragHandle)
          const SizedBox(
            height: AppSizes.minTouchTarget,
            child: Center(child: DragHandle()),
          ),
        Flexible(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (widget.isExpanded) _buildFacilityDetails(widget.facility),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isOpen24_7(Facility facility) {
    return facility.hoursDisplay.toLowerCase().contains('24 hours') ||
        facility.hoursDisplay.toLowerCase().contains('24/7');
  }

  void _openDirections() {
    final facility = widget.facility;
    if (facility.hasAddress) {
      // `address` already carries the city, state, and ZIP. Chooser +
      // remembered preference — neither platform exposes its default map app.
      MapLauncherService.openDirections(context, address: facility.address);
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

  /// Directions, Call, Website — what people came for, directly under the
  /// name rather than below the fold. Call and Website appear only when the
  /// facility has them. Side by side at ordinary text sizes; stacked once the
  /// labels would no longer fit.
  Widget _buildActions(Facility facility) {
    final l10n = AppLocalizations.of(context)!;
    final phone = facility.primaryPhone;
    final hasPhone = phone.isNotEmpty && phone != 'Phone not available';
    final website = facility.website;
    final hasWebsite = website != null && website.isNotEmpty;
    final stacked = MediaQuery.textScalerOf(context).scale(100) / 100 >= 1.5;

    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.sm,
    );
    const minimumSize = Size(0, _actionMinHeight);
    // Set on the button, not the label, so the label keeps the button's own
    // foreground color.
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    Widget label(IconData icon, String text, {String? spoken}) => Flex(
          direction: stacked ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppIconSize.lg),
            const SizedBox.square(dimension: AppSpacing.xs),
            Flexible(
              child: Text(
                text,
                semanticsLabel: spoken,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );

    final actions = [
      FilledButton(
        onPressed: _openDirections,
        style: FilledButton.styleFrom(
          padding: padding,
          minimumSize: minimumSize,
          textStyle: textStyle,
        ),
        child: label(Icons.directions, l10n.cardDirections),
      ),
      if (hasPhone)
        OutlinedButton(
          onPressed: () => widget.onLaunchUrl('tel:${dialablePhone(phone)}'),
          style: OutlinedButton.styleFrom(
            padding: padding,
            minimumSize: minimumSize,
            textStyle: textStyle,
          ),
          // Read out with the number, and still starting with the word on
          // the button.
          child: label(
            Icons.call,
            l10n.cardCall,
            spoken: l10n.cardCallNumber(formatPhoneForDisplay(phone)),
          ),
        ),
      if (hasWebsite)
        OutlinedButton(
          onPressed: () => widget.onLaunchUrl(website),
          style: OutlinedButton.styleFrom(
            padding: padding,
            minimumSize: minimumSize,
            textStyle: textStyle,
          ),
          child: label(Icons.language, l10n.cardWebsite),
        ),
    ];

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, action) in actions.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            action,
          ],
        ],
      );
    }
    return Row(
      children: [
        for (final (index, action) in actions.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: action),
        ],
      ],
    );
  }

  Widget _buildFacilityDetails(Facility facility) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActions(facility),
          // The address row is a full target tall and centers its text, so
          // the same small gap above it as the divider leaves below it puts
          // a one-line address midway between the buttons and the divider.
          if (facility.hasAddress) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildAddressRow(facility.address),
          ] else
            const SizedBox(height: AppSpacing.md),
          if (facility.description.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            Text(facility.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
          ],
          ..._buildAtAGlanceSection(facility),
          ..._buildServicesSection(facility),
          const Divider(height: AppSpacing.md),
          _buildHours(facility),
          // How fresh all of the above is, where the team has checked it.
          if (facility.lastCheckedAt case final DateTime checked)
            Text(
              l10n.cardLastUpdated(checked.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (widget.onRate != null || widget.onSubmitCorrection != null)
            const Divider(height: AppSpacing.md),
          // Full width so these don't wrap awkwardly in a narrow column.
          if (widget.onRate != null) ...[
            _buildActionLink(
              Icons.thumbs_up_down_outlined,
              l10n.cardRatePromptLead,
              l10n.cardRatePromptAction,
              widget.onRate,
            ),
          ],
          if (widget.onSubmitCorrection != null)
            _buildActionLink(
              Icons.edit_note_outlined,
              l10n.cardCorrectionPromptLead,
              l10n.cardCorrectionPromptAction,
              widget.onSubmitCorrection,
            ),
        ],
      ),
    );
  }

  /// Full-width tappable "form" action (rate / submit corrections). The [lead]
  /// is bold in the default text color; only the [action] reads as a link
  /// (underlined, in the link color) to flag the submittal route.
  Widget _buildActionLink(
    IconData icon,
    String lead,
    String action,
    VoidCallback? onTap,
  ) {
    final theme = Theme.of(context);
    final link = theme.colorScheme.tertiaryText;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.md, color: link),
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
                        color: link,
                        decoration: TextDecoration.underline,
                        decorationColor: link,
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

  /// Fewer days than this stay in one column: two beside one reads as a
  /// mistake.
  static const int _minHoursToSplit = 4;

  /// A day's hours, or that it is closed, or that nobody knows: the three
  /// must not look alike.
  String _hoursRange(OperatingHours h) {
    final l10n = AppLocalizations.of(context)!;
    if (h.opensAt != null && h.closesAt != null) {
      return '${_formatTime(h.opensAt!)} - ${_formatTime(h.closesAt!)}';
    }
    return h.isClosed ? l10n.cardHoursClosed : l10n.cardHoursUnknown;
  }

  /// The width the longest day and the longest time need side by side, at
  /// the current text size.
  double _widestHoursRow(List<OperatingHours> hours, TextStyle? style) {
    double widest(Iterable<String> texts, TextStyle? style) {
      var width = 0.0;
      for (final text in texts) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        if (painter.width > width) width = painter.width;
        painter.dispose();
      }
      return width;
    }

    return widest(hours.map((h) => _formatDay(h.day)), style) +
        AppSpacing.md +
        widest(
          hours.map(_hoursRange),
          style?.copyWith(fontWeight: FontWeight.w400),
        );
  }

  /// A table, so the day column is as wide as its longest name at any text
  /// size and the times stay aligned beside it.
  Widget _buildHoursTable(List<OperatingHours> hours, TextStyle? style) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: [
        for (final h in hours)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: AppSpacing.md,
                  bottom: AppSpacing.xs,
                ),
                child: Text(_formatDay(h.day), style: style),
              ),
              Text(
                _hoursRange(h),
                style: style?.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHours(Facility facility) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final style = theme.textTheme.labelSmall;

    final Widget body;
    if (_isOpen24_7(facility)) {
      body = Text(
        l10n.cardOpen247,
        style: style?.copyWith(fontWeight: FontWeight.w700),
      );
    } else if (facility.hours.isEmpty) {
      body = Text(
        l10n.cardContactForHours,
        style: style?.copyWith(
          fontWeight: FontWeight.w400,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final hours = facility.hours;
          // Side by side when both halves of the week fit, so a short list
          // doesn't leave half the card empty; one column otherwise, as at
          // large text sizes.
          final half = (constraints.maxWidth - AppSpacing.xxl) / 2;
          if (hours.length < _minHoursToSplit ||
              _widestHoursRow(hours, style) > half) {
            return _buildHoursTable(hours, style);
          }
          final firstColumn = (hours.length + 1) ~/ 2;
          // IntrinsicHeight, so the rule between the columns is as tall as
          // the longer of them.
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildHoursTable(hours.sublist(0, firstColumn), style),
                ),
                const DashedVerticalDivider(width: AppSpacing.xxl),
                Expanded(
                  child: _buildHoursTable(hours.sublist(firstColumn), style),
                ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.cardHours, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        body,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  /// Services block (plain-language summary preferred, chips as fallback).
  /// Returns an empty list when the facility has no service data.
  List<Widget> _buildServicesSection(Facility facility) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final title = Text(l10n.cardServices, style: theme.textTheme.titleMedium);

    if (facility.servicesSummary != null &&
        facility.servicesSummary!.isNotEmpty) {
      final muted = theme.colorScheme.onSurfaceVariant;
      return [
        const Divider(height: AppSpacing.md),
        title,
        const SizedBox(height: AppSpacing.sm),
        Text(facility.servicesSummary!, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        // Upright, with a mark: italics at this size are the hardest text on
        // the card to read, and this line is a warning.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: AppIconSize.sm,
              color: muted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.cardServicesAiDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          ],
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
              TagChip(label: service, color: theme.colorScheme.tertiaryText),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ];
    }
    return const [];
  }

  /// "At a glance" eligibility chips + summary. Returns an empty list (no
  /// leading divider) when the facility has neither, so it can sit at the top
  /// of the details block without an orphan separator.
  List<Widget> _buildAtAGlanceSection(Facility facility) {
    final eligibilityChips = _buildEligibilityChips(facility);
    final hasSummary = facility.otherEligibilitySummary != null &&
        facility.otherEligibilitySummary!.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;
    final facts = [
      if (facility.eligibility?.incomeLimit case final String limit)
        _buildFactRow(Icons.payments_outlined, l10n.cardIncomeLimit, limit),
      if (facility.eligibility?.serviceArea case final String area)
        _buildFactRow(Icons.map_outlined, l10n.cardServiceArea, area),
    ];
    if (eligibilityChips.isEmpty && !hasSummary && facts.isEmpty) {
      return const [];
    }

    final theme = Theme.of(context);
    return [
      const Divider(height: AppSpacing.md),
      if (eligibilityChips.isNotEmpty || facts.isNotEmpty)
        Text(l10n.cardAtAGlance, style: theme.textTheme.titleMedium),
      if (eligibilityChips.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: eligibilityChips,
        ),
      ],
      for (final fact in facts) ...[
        const SizedBox(height: AppSpacing.sm),
        fact,
      ],
      if (hasSummary) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          facility.otherEligibilitySummary!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.xs),
    ];
  }

  /// The street address, which a tap copies; the copy icon says so. Pasting
  /// it beats retyping it into a maps app, a message, or a form.
  Widget _buildAddressRow(String address) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      onTapHint: l10n.cardCopyAddress,
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: address));
          if (!mounted ||
              !FacilityCard.confirmsCopy(Theme.of(context).platform)) {
            return;
          }
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.cardAddressCopied)));
        },
        borderRadius: AppRadii.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTouchTarget,
          ),
          child: Row(
            children: [
              Icon(Icons.place_outlined, size: AppIconSize.sm, color: muted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(address, style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.content_copy_outlined,
                size: AppIconSize.sm,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A labelled line of free text under the chips ("Income limit: …").
  Widget _buildFactRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppIconSize.sm, color: theme.colorScheme.secondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label + AppLocalizations.of(context)!.labelSeparator,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEligibilityChips(Facility facility) {
    final elig = facility.eligibility;
    if (elig == null) return [];

    final chips = <Widget>[];
    final color = Theme.of(context).colorScheme.primaryText;
    void addChip(String label, EligibilityValue value, IconData icon) {
      if (value == EligibilityValue.yes) {
        chips.add(TagChip(label: label, icon: icon, color: color));
      }
    }

    final l10n = AppLocalizations.of(context)!;
    addChip(l10n.chipMedicaid, elig.acceptsMedicaid, Icons.badge_outlined);
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
}
