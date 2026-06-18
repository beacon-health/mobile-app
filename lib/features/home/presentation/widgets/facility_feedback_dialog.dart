import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a modal dialog where an authenticated user can submit feedback
/// (thumbs up/down + free-text comment) about [facility]. Inserts a row into
/// the `facility_feedback` Supabase table.
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

  bool? _isThumbsUp;
  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  bool get _canSubmit =>
      !_isSubmitting && _isThumbsUp != null && _selectedTags.isNotEmpty;

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
    // The `facility_feedback.comment` column stays text — store the selected
    // tags as a comma-separated list (no schema change needed).
    final comment = _selectedTags.join(', ');

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      // Belt-and-suspenders: the home page already blocks this for guests,
      // but if we got here somehow without a user, surface a snackbar rather
      // than letting the insert fail silently with a 401.
      _showSnack('Sign in required to submit feedback.', isError: true);
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await supabase.from('facility_feedback').insert({
        'user_id': userId,
        'facility_id': widget.facility.id,
        'rating': rating ? 'up' : 'down',
        'comment': comment,
      });
      // Drop this facility from "Recently Viewed" — feedback is implicitly
      // "I'm done with this one" feedback.
      RecentFacilitiesService().removeFacility(widget.facility.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack('Thanks for your feedback!');
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityFeedbackDialog._submit',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      // In debug builds we surface the underlying error so the developer
      // can see RLS / missing-table / FK-violation specifics in the snackbar
      // without digging through logs. Release builds get a clean message.
      final msg = kDebugMode
          ? "Couldn't send feedback: ${_describeError(e)}"
          : "Couldn't send feedback. Please try again.";
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
              onSelected: _isSubmitting ? null : (_) => _toggleTag(tag),
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RatingButton(
                  icon: Icons.thumb_up,
                  outlinedIcon: Icons.thumb_up_outlined,
                  activeColor: AppTheme.resedaGreen,
                  isActive: _isThumbsUp == true,
                  onTap: _isSubmitting ? null : () => _setRating(true),
                ),
                const SizedBox(width: 24),
                _RatingButton(
                  icon: Icons.thumb_down,
                  outlinedIcon: Icons.thumb_down_outlined,
                  activeColor: AppTheme.bittersweet,
                  isActive: _isThumbsUp == false,
                  onTap: _isSubmitting ? null : () => _setRating(false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTagSelector(colorScheme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
              : const Text('Submit'),
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
