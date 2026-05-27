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
  final TextEditingController _commentController = TextEditingController();
  bool? _isThumbsUp;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    // Rebuild so the Submit button enable/disable state stays in sync with
    // the text field content.
    setState(() {});
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _isThumbsUp != null &&
      _commentController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final rating = _isThumbsUp;
    final comment = _commentController.text.trim();
    if (rating == null || comment.isEmpty) return;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(
        widget.facility.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: Column(
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
                onTap: _isSubmitting
                    ? null
                    : () => setState(() => _isThumbsUp = true),
              ),
              const SizedBox(width: 24),
              _RatingButton(
                icon: Icons.thumb_down,
                outlinedIcon: Icons.thumb_down_outlined,
                activeColor: AppTheme.bittersweet,
                isActive: _isThumbsUp == false,
                onTap: _isSubmitting
                    ? null
                    : () => setState(() => _isThumbsUp = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: 'Tell us about your experience...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
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
