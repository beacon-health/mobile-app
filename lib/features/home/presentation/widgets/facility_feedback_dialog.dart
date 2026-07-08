import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/facility_feedback_service.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a modal dialog where an authenticated user can submit (or edit)
/// feedback — thumbs up/down + quick-select tags — about [facility].
///
/// On open it loads any feedback the user has already submitted for this
/// facility and pre-fills the form, so re-opening edits in place rather than
/// creating a duplicate (writes go through [FacilityFeedbackService.submit],
/// an upsert keyed on `(user_id, facility_id)`). When existing feedback is
/// present a **Remove** action is offered.
///
/// Guests should not reach this — call `showSignInPromptDialog` instead.
/// (The home page enforces this gate before calling here.)
Future<void> showFacilityFeedbackDialog(
  BuildContext context, {
  required Facility facility,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _FacilityFeedbackDialog(facility: facility),
  );
}

class _FacilityFeedbackDialog extends StatefulWidget {
  const _FacilityFeedbackDialog({required this.facility});

  final Facility facility;

  @override
  State<_FacilityFeedbackDialog> createState() =>
      _FacilityFeedbackDialogState();
}

class _FacilityFeedbackDialogState extends State<_FacilityFeedbackDialog> {
  /// Quick-select tags shown for a thumbs-up rating.
  static const List<String> _positiveTags = [
    'Friendly staff',
    'Minimal wait times',
    'Clean facility',
    'Helpful with paperwork',
    'Affordable or free',
    'Easy to reach by phone',
    'Welcoming environment',
    'Knowledgeable providers',
  ];

  /// Quick-select tags shown for a thumbs-down rating.
  static const List<String> _negativeTags = [
    'Long wait times',
    'Slow service',
    'Unfriendly staff',
    'Hard to reach by phone',
    'Confusing paperwork',
    'Unexpected costs',
    'Hard to find',
    'Services not as described',
  ];

  final FacilityFeedbackService _feedbackService = FacilityFeedbackService();

  bool? _isThumbsUp;
  final Set<String> _selectedTags = {};

  /// True while loading any existing feedback for this facility.
  bool _loadingExisting = true;

  /// True when the user already had feedback for this facility (edit mode).
  bool _hasExisting = false;

  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _busy => _isSubmitting || _isDeleting;

  bool get _canSubmit =>
      !_busy && _isThumbsUp != null && _selectedTags.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// Pre-fills the form with the user's existing feedback, if any.
  Future<void> _loadExisting() async {
    try {
      final existing =
          await _feedbackService.getForFacility(widget.facility.id);
      if (!mounted) return;
      if (existing != null) {
        final canonical =
            existing.isThumbsUp ? _positiveTags : _negativeTags;
        setState(() {
          _hasExisting = true;
          _isThumbsUp = existing.isThumbsUp;
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
        context: 'FacilityFeedbackDialog._loadExisting',
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

  Future<void> _submit() async {
    final rating = _isThumbsUp;
    if (rating == null || _selectedTags.isEmpty) return;

    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser?.id == null) {
      // Belt-and-suspenders: the home page already blocks this for guests,
      // but if we got here somehow without a user, surface a snackbar rather
      // than letting the write fail silently with a 401.
      _showSnack('Sign in required to submit feedback.', isError: true);
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);
    final wasEditing = _hasExisting;
    try {
      await _feedbackService.submit(
        facilityId: widget.facility.id,
        isThumbsUp: rating,
        tags: _selectedTags,
      );
      // A fresh submission means "I'm done with this one" — drop it from
      // Recently Viewed. Edits come from the Your Feedback list, where the
      // facility usually isn't in Recently Viewed anyway (no-op if absent).
      if (!wasEditing) {
        RecentFacilitiesService().removeFacility(widget.facility.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(wasEditing ? 'Feedback updated.' : 'Thanks for your feedback!');
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityFeedbackDialog._submit',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      // Debug builds surface the underlying error (RLS / missing-table /
      // FK / unique-constraint specifics); release builds get a clean message.
      final msg = kDebugMode
          ? "Couldn't send feedback: ${_describeError(e)}"
          : "Couldn't send feedback. Please try again.";
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
      _showSnack('Feedback removed.');
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityFeedbackDialog._remove',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final msg = kDebugMode
          ? "Couldn't remove feedback: ${_describeError(e)}"
          : "Couldn't remove feedback. Please try again.";
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

  /// Multi-select tag chips, switched by the chosen rating. Shown only after a
  /// thumbs up/down is picked.
  Widget _buildTagSelector(ColorScheme colorScheme) {
    if (_isThumbsUp == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Choose 👍 or 👎, then add a few quick details.',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
      );
    }
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
                        'You already rated this — update it below.',
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
                  const SizedBox(height: 16),
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
                      : const Text('Remove'),
                ),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_hasExisting ? 'Update' : 'Submit'),
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
