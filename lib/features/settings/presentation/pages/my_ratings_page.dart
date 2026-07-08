import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/facility_feedback_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/widgets/facility_rating_dialog.dart';
import 'package:beacon_app/features/map/data/supabase_facility_service.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Lists the ratings the signed-in user has submitted, and lets them edit or
/// remove each one (MVP_RELEASE.md §2.7 / §2.9).
///
/// Rating rows store only a `facility_id`, so facility names are resolved by
/// id from the view (region-independent, same path as Favorites). Tapping a
/// row re-opens [showFacilityRatingDialog] pre-filled for in-place editing.
class MyRatingsPage extends StatefulWidget {
  const MyRatingsPage({super.key});

  @override
  State<MyRatingsPage> createState() => _MyRatingsPageState();
}

class _MyRatingsPageState extends State<MyRatingsPage> {
  final FacilityFeedbackService _feedbackService = FacilityFeedbackService();
  final SupabaseFacilityService _facilityService = SupabaseFacilityService();

  bool _loading = true;
  List<FacilityFeedbackEntry> _entries = const [];

  /// facility_id → resolved facility (for display + the edit dialog).
  Map<String, Facility> _facilitiesById = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final entries = await _feedbackService.getMine();
      final ids = entries.map((e) => e.facilityId).toSet().toList();
      final facilities = await _facilityService.getFacilitiesByIds(ids);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _facilitiesById = {for (final f in facilities) f.id: f};
        _loading = false;
      });
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MyRatingsPage._load',
      );
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Returns the resolved facility for [entry], or a minimal placeholder so the
  /// row still renders (and stays editable/removable) if the facility dropped
  /// out of the dataset.
  Facility _facilityFor(FacilityFeedbackEntry entry) {
    return _facilitiesById[entry.facilityId] ??
        Facility(
          id: entry.facilityId,
          name: 'Facility',
          description: '',
          location: const LatLng(0, 0),
          address: '',
          city: '',
          state: '',
        );
  }

  Future<void> _edit(FacilityFeedbackEntry entry) async {
    await showFacilityRatingDialog(context, facility: _facilityFor(entry));
    // The dialog may have updated or removed the entry — refresh.
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsYourRatings),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _entries.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => _buildRow(_entries[i]),
                    ),
            ),
    );
  }

  Widget _buildRow(FacilityFeedbackEntry entry) {
    final facility = _facilityFor(entry);
    final accent =
        entry.isThumbsUp ? AppTheme.resedaGreen : AppTheme.bittersweet;
    final date = entry.visitedOn ?? entry.submittedAt;
    final subtitle = [
      if (entry.tags.isNotEmpty) entry.tags.join(', '),
      if (date != null)
        AppLocalizations.of(context)!.ratingsVisitedOn(
          MaterialLocalizations.of(context).formatMediumDate(date),
        ),
    ].join(' · ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.15),
        child: Icon(
          entry.isThumbsUp ? Icons.thumb_up : Icons.thumb_down,
          color: accent,
          size: 20,
        ),
      ),
      title: Text(
        facility.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: const Icon(Icons.edit_outlined, size: 20),
      onTap: () => _edit(entry),
    );
  }

  Widget _buildEmptyState() {
    // Wrapped in a scroll view so RefreshIndicator still works when empty.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.thumbs_up_down_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.ratingsEmptyTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.ratingsEmptyHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
