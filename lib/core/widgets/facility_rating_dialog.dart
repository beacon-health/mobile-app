import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/facility_feedback_service.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modal for rating [facility] — thumbs up/down and visit date required, tags
/// optional. Pre-fills any existing rating so re-opening edits in place.
/// Callers gate guests with `showSignInPromptDialog`.
Future<void> showFacilityRatingDialog(
  BuildContext context, {
  required Facility facility,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _FacilityRatingDialog(facility: facility),
  );
}

class _FacilityRatingDialog extends StatefulWidget {
  const _FacilityRatingDialog({required this.facility});

  final Facility facility;

  @override
  State<_FacilityRatingDialog> createState() => _FacilityRatingDialogState();
}

class _FacilityRatingDialogState extends State<_FacilityRatingDialog> {
  /// Quick-select tags shown for a thumbs-up rating (max 5 by design).
  static const List<String> _positiveTags = [
    'Friendly staff',
    'Minimal wait times',
    'Helpful with paperwork',
    'Affordable or free',
    'Welcoming environment',
  ];

  /// Quick-select tags shown for a thumbs-down rating (max 5 by design).
  static const List<String> _negativeTags = [
    'Long wait times',
    'Unfriendly staff',
    'Hard to reach by phone',
    'Unexpected costs',
    'Services not as described',
  ];

  final FacilityFeedbackService _feedbackService = FacilityFeedbackService();

  bool? _isThumbsUp;
  final Set<String> _selectedTags = {};

  /// Date of visit — required, defaults to today, past dates only.
  DateTime _visitedOn = DateTime.now();

  /// True while loading any existing rating for this facility.
  bool _loadingExisting = true;

  /// True when the user already rated this facility (edit mode).
  bool _hasExisting = false;

  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _busy => _isSubmitting || _isDeleting;

  /// Tags are optional; rating + date are required (date always has a value).
  bool get _canSubmit => !_busy && _isThumbsUp != null;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// Pre-fills the form with the user's existing rating, if any.
  Future<void> _loadExisting() async {
    try {
      final existing =
          await _feedbackService.getForFacility(widget.facility.id);
      if (!mounted) return;
      if (existing != null) {
        final canonical = existing.isThumbsUp ? _positiveTags : _negativeTags;
        setState(() {
          _hasExisting = true;
          _isThumbsUp = existing.isThumbsUp;
          _visitedOn = existing.visitedOn ?? _visitedOn;
          _selectedTags
            ..clear()
            // Keep only tags still offered for this rating, so the chips and
            // the stored value stay in sync if the tag lists ever change.
            ..addAll(existing.tags.where(canonical.contains));
        });
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityRatingDialog._loadExisting',
      );
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  void _setRating(bool thumbsUp) {
    setState(() {
      // Switching rating swaps the tag set, so clear stale selections.
      if (_isThumbsUp != thumbsUp) _selectedTags.clear();
      _isThumbsUp = thumbsUp;
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (!_selectedTags.add(tag)) _selectedTags.remove(tag);
    });
  }

  Future<void> _pickVisitDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitedOn.isAfter(now) ? now : _visitedOn,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _visitedOn = picked);
    }
  }

  Future<void> _submit() async {
    final rating = _isThumbsUp;
    if (rating == null) return;

    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser?.id == null) {
      // Callers already gate guests; this keeps a stray call from failing
      // silently with a 401.
      _showSnack(
        AppLocalizations.of(context)!.ratingSignInRequired,
        isError: true,
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);
    final wasEditing = _hasExisting;
    try {
      await _feedbackService.submit(
        facilityId: widget.facility.id,
        isThumbsUp: rating,
        visitedOn: _visitedOn,
        tags: _selectedTags,
      );
      // A fresh rating means the user is done with it; drop it from Recently
      // Viewed (no-op if absent).
      if (!wasEditing) {
        RecentFacilitiesService().removeFacility(widget.facility.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(
        wasEditing
            ? AppLocalizations.of(context)!.ratingUpdated
            : AppLocalizations.of(context)!.ratingThanks,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityRatingDialog._submit',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      // Debug builds surface the underlying error (RLS / missing-column /
      // unique-constraint specifics); release builds get a clean message.
      final msg = kDebugMode
          ? "Couldn't send rating: ${_describeError(e)}"
          : AppLocalizations.of(context)!.ratingSendFailed;
      _showSnack(msg, isError: true);
    }
  }

  Future<void> _remove() async {
    setState(() => _isDeleting = true);
    try {
      await _feedbackService.delete(widget.facility.id);
      RecentFacilitiesService().removeFacility(widget.facility.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(AppLocalizations.of(context)!.ratingRemoved);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityRatingDialog._remove',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final msg = kDebugMode
          ? "Couldn't remove rating: ${_describeError(e)}"
          : AppLocalizations.of(context)!.ratingRemoveFailed;
      _showSnack(msg, isError: true);
    }
  }

  String _describeError(Object e) {
    if (e is PostgrestException) {
      return '${e.code ?? ''} ${e.message}'.trim();
    }
    return e.toString();
  }

  void _showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  /// Tappable "Date visited" row; opens a past-only date picker.
  Widget _buildDateRow(ColorScheme colorScheme) {
    final formatted =
        MaterialLocalizations.of(context).formatMediumDate(_visitedOn);
    return InkWell(
      onTap: _busy ? null : _pickVisitDate,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.ratingDateVisited,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              formatted,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// Multi-select tag chips, switched by the chosen rating. Shown only after a
  /// thumbs up/down is picked; selection is optional.
  Widget _buildTagSelector(ColorScheme colorScheme) {
    if (_isThumbsUp == null) return const SizedBox.shrink();
    final tags = _isThumbsUp! ? _positiveTags : _negativeTags;
    final accent = _isThumbsUp! ? AppTheme.resedaGreen : AppTheme.bittersweet;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tag in tags)
            FilterChip(
              label: Text(tag),
              selected: _selectedTags.contains(tag),
              onSelected: _busy ? null : (_) => _toggleTag(tag),
              showCheckmark: false,
              backgroundColor: Colors.transparent,
              selectedColor: accent.withValues(alpha: 0.18),
              side: BorderSide(
                color: _selectedTags.contains(tag)
                    ? accent
                    : Theme.of(context).dividerColor,
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                color: _selectedTags.contains(tag)
                    ? accent
                    : colorScheme.onSurface,
                fontWeight: _selectedTags.contains(tag)
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(
        widget.facility.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: _loadingExisting
          ? const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasExisting)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        AppLocalizations.of(context)!.ratingAlreadyRated,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RatingButton(
                        icon: Icons.thumb_up,
                        outlinedIcon: Icons.thumb_up_outlined,
                        activeColor: AppTheme.resedaGreen,
                        isActive: _isThumbsUp == true,
                        onTap: _busy ? null : () => _setRating(true),
                      ),
                      const SizedBox(width: 24),
                      _RatingButton(
                        icon: Icons.thumb_down,
                        outlinedIcon: Icons.thumb_down_outlined,
                        activeColor: AppTheme.bittersweet,
                        isActive: _isThumbsUp == false,
                        onTap: _busy ? null : () => _setRating(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDateRow(colorScheme),
                  const SizedBox(height: 8),
                  _buildTagSelector(colorScheme),
                ],
              ),
            ),
      actions: _loadingExisting
          ? null
          : [
              if (_hasExisting)
                TextButton(
                  onPressed: _busy ? null : _remove,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.bittersweet,
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.ratingRemove),
                ),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.commonCancel),
              ),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _hasExisting
                            ? AppLocalizations.of(context)!.ratingUpdate
                            : AppLocalizations.of(context)!.ratingSubmit,
                      ),
              ),
            ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.icon,
    required this.outlinedIcon,
    required this.activeColor,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData outlinedIcon;
  final Color activeColor;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isActive ? icon : outlinedIcon,
          size: 36,
          color: isActive
              ? activeColor
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
