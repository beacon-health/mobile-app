import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter/material.dart';

class FacilityCard extends StatefulWidget {
  final Facility facility;
  final bool isExpanded;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleExpand;
  final Widget Function(String?) buildCategoryIcon;
  final Future<void> Function(String) onLaunchUrl;
  final bool showExpandButton;

  const FacilityCard({
    super.key,
    required this.facility,
    required this.isExpanded,
    required this.onToggleFavorite,
    required this.onToggleExpand,
    required this.buildCategoryIcon,
    required this.onLaunchUrl,
    this.showExpandButton = true,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      clipBehavior: Clip.none,
      color: isDark ? null : AppTheme.honeydew,
      child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      '${widget.facility.city}, ${widget.facility.state}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                if (widget.isExpanded) _buildFacilityDetails(widget.facility),
                if (!widget.isExpanded) const SizedBox(height: 8),
              ],
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
                  color: widget.facility.isFavorite ? Colors.red : null,
                  size: 20,
                ),
                onPressed: widget.onToggleFavorite,
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

  Widget _buildFacilityDetails(Facility facility) {
    final is24_7 = _isOpen24_7(facility);

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
          const Divider(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Steps',
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
                        value: 'Visit website',
                        onTap: () =>
                            widget.onLaunchUrl(widget.facility.website!),
                      )
                    else
                      _buildNextStepItem(
                        icon: Icons.language,
                        value: 'Website not available',
                        onTap: () {},
                      ),
                    if (facility.primaryPhone.isNotEmpty &&
                        facility.primaryPhone != 'Phone not available')
                      _buildNextStepItem(
                        icon: Icons.phone,
                        value: facility.primaryPhone,
                        onTap: () => widget.onLaunchUrl(
                          'tel:${facility.primaryPhone.replaceAll(RegExp('[^0-9+]'), '')}',
                        ),
                      ),
                    _buildNextStepItem(
                      icon: Icons.directions,
                      value: 'Get directions',
                      onTap: () {
                        final hasValidAddress = facility.address.isNotEmpty &&
                            !facility.address
                                .toLowerCase()
                                .contains('not available');
                        final hasValidCity = facility.city.isNotEmpty;
                        final hasValidState = facility.state.isNotEmpty;

                        if (hasValidAddress && hasValidCity && hasValidState) {
                          final fullAddress =
                              '${facility.address}, ${facility.city}, ${facility.state}'
                                  .trim();
                          final encodedAddress =
                              Uri.encodeComponent(fullAddress);
                          widget.onLaunchUrl(
                            'https://maps.apple.com/?q=$encodedAddress',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Address information not available for this facility',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
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
                      'Hours',
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
                          'Contact facility for hours',
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
          ),
          const SizedBox(height: 4),
          const Divider(height: 8),
          _buildEligibilitySection(facility),
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

  Widget _buildEligibilitySection(Facility facility) {
    final eligibilityChips = _buildEligibilityChips(facility);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (facility.servicesSummary != null &&
            facility.servicesSummary!.isNotEmpty) ...[
          Text(
            'Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
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
        ] else if (facility.services.isNotEmpty) ...[
          Text(
            'Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
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
        ],
        if (eligibilityChips.isNotEmpty) ...[
          Text(
            'At a Glance',
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
        if (facility.otherEligibilitySummary != null &&
            facility.otherEligibilitySummary!.isNotEmpty) ...[
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
      ],
    );
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

    addChip('Walk-ins', elig.acceptsWalkins, Icons.directions_walk);
    addChip('Free', elig.freeServicesAvailable, Icons.money_off);
    addChip('Telehealth', elig.telehealthAvailable, Icons.videocam);
    addChip('Accessible', elig.wheelchairAccessible, Icons.accessible);
    addChip('Sliding Scale', elig.slidingScaleAvailable, Icons.tune);
    addChip(
      'Other Languages',
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
            is24_7 ? 'Open 24/7' : hours,
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
