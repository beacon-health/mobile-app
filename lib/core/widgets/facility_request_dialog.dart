import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/facility_request_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a modal dialog where an authenticated user can request a facility be
/// added to Beacon. Requires **name + website**.
///
/// Submissions land in the `facility_requests` staging table (`request_type =
/// 'new'`) for internal review. Guests should not reach this — callers gate
/// with `showSignInPromptDialog`.
Future<void> showFacilityRequestDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _FacilityRequestDialog(),
  );
}

class _FacilityRequestDialog extends StatefulWidget {
  const _FacilityRequestDialog();

  @override
  State<_FacilityRequestDialog> createState() => _FacilityRequestDialogState();
}

class _FacilityRequestDialogState extends State<_FacilityRequestDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FacilityRequestService _requestService = FacilityRequestService();

  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (Supabase.instance.client.auth.currentUser?.id == null) {
      _showSnack(
        AppLocalizations.of(context)!.requestSignInRequired,
        isError: true,
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _requestService.submitNew(
        facilityName: _nameController.text,
        website: _websiteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(AppLocalizations.of(context)!.requestSubmitted);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityRequestDialog._submit',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final msg = kDebugMode
          ? "Couldn't submit request: $e"
          : AppLocalizations.of(context)!.requestSubmitFailed;
      _showSnack(msg, isError: true);
    }
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

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: !_isSubmitting,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l10n.requestDialogTitle,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.requestDialogIntro,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _field(
                _nameController,
                l10n.requestFieldName,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.requestFieldNameError
                    : null,
              ),
              _field(
                _websiteController,
                l10n.requestFieldWebsite,
                keyboardType: TextInputType.url,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.requestFieldWebsiteError
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.ratingSubmit),
        ),
      ],
    );
  }
}
