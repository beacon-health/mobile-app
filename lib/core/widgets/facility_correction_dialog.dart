import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/facility_request_service.dart';
import 'package:beacon_app/core/utils/phone_format.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a modal where an authenticated user can submit corrections to an
/// existing [facility] — name, website, phone, hours, address. Fields are
/// pre-filled with current values; the user edits what's wrong.
///
/// Submissions land in `facility_requests` (`request_type = 'correction'`,
/// `facility_id` set) for internal review. Guests should not reach
/// this — callers gate with `showSignInPromptDialog`.
Future<void> showFacilityCorrectionDialog(
  BuildContext context, {
  required Facility facility,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _FacilityCorrectionDialog(facility: facility),
  );
}

class _FacilityCorrectionDialog extends StatefulWidget {
  const _FacilityCorrectionDialog({required this.facility});

  final Facility facility;

  @override
  State<_FacilityCorrectionDialog> createState() =>
      _FacilityCorrectionDialogState();
}

class _FacilityCorrectionDialogState extends State<_FacilityCorrectionDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FacilityRequestService _requestService = FacilityRequestService();

  late final TextEditingController _nameController;
  late final TextEditingController _websiteController;
  late final TextEditingController _phoneController;
  late final TextEditingController _hoursController;
  late final TextEditingController _addressController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final f = widget.facility;
    final phone = f.primaryPhone;
    _nameController = TextEditingController(text: f.name);
    _websiteController = TextEditingController(text: f.website ?? '');
    _phoneController = TextEditingController(
      text: phone == 'Phone not available' ? '' : formatPhoneForDisplay(phone),
    );
    _hoursController = TextEditingController(
      text: f.hours.isEmpty ? '' : f.hoursDisplay,
    );
    _addressController = TextEditingController(
      text: f.address == 'Address not available' ? '' : f.address,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _addressController.dispose();
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
      await _requestService.submitCorrection(
        facilityId: widget.facility.id,
        facilityName: _nameController.text,
        website: _websiteController.text,
        phone: _phoneController.text,
        hours: _hoursController.text,
        address: _addressController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(AppLocalizations.of(context)!.correctionSubmitted);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'FacilityCorrectionDialog._submit',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      final msg = kDebugMode
          ? "Couldn't submit correction: $e"
          : AppLocalizations.of(context)!.correctionSubmitFailed;
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
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: !_isSubmitting,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l10n.correctionDialogTitle,
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
                  l10n.correctionDialogIntro,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _field(_nameController, l10n.correctionFieldName),
              _field(
                _websiteController,
                l10n.correctionFieldWebsite,
                keyboardType: TextInputType.url,
              ),
              _field(
                _phoneController,
                l10n.correctionFieldPhone,
                keyboardType: TextInputType.phone,
              ),
              _field(_hoursController, l10n.correctionFieldHours, maxLines: 2),
              _field(
                _addressController,
                l10n.correctionFieldAddress,
                maxLines: 2,
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
