import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/utils/coverage_text.dart';
import 'package:beacon_app/core/widgets/coverage_notice.dart';
import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:beacon_app/features/auth/presentation/widgets/onboarding_scaffold.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZipEntryPage extends StatefulWidget {
  const ZipEntryPage({super.key, this.prefilledZip, this.locationOff = false});

  /// Optional ZIP to pre-populate the input. Used when returning a recently
  /// signed-in guest user back through the location flow.
  final String? prefilledZip;

  /// The person asked to use their location and the phone said no. Says so,
  /// since otherwise they chose one option and silently got the other.
  final bool locationOff;

  @override
  State<ZipEntryPage> createState() => _ZipEntryPageState();
}

class _ZipEntryPageState extends State<ZipEntryPage> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initial = widget.prefilledZip ?? '';
    _controller = TextEditingController(
      text: RegExp(r'^\d{5}$').hasMatch(initial) ? initial : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final zip = _controller.text.trim();
    final result = await ZipCodeService().setZipCode(zip);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = result == ZipResult.saved
          ? null
          : zipErrorMessage(AppLocalizations.of(context)!, result);
    });
    if (result == ZipResult.saved) finishLocationOnboarding(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: OnboardingScaffold(
        step: 1,
        children: [
          OnboardingHeading(
            title: l10n.zipEntryTitle,
            subtitle: widget.locationOff
                ? l10n.zipEntryLocationOff
                : l10n.zipEntrySubtitle,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.postalCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            autofocus: true,
            // The label stays put above the digits, so the field still says
            // what it is once someone starts typing.
            decoration: InputDecoration(
              labelText: l10n.settingsZipCode,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              helperText: l10n.zipEntryHelper,
              errorText: _errorMessage,
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
            ),
            style: AppTypography.zipInput,
            validator: (value) {
              final trimmed = (value ?? '').trim();
              if (trimmed.length != 5) {
                return l10n.zipEntryInvalid;
              }
              return null;
            },
            onFieldSubmitted: (_) => _isLoading ? null : _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: AppTheme.secondaryFilledButton(context),
            child: _isLoading
                ? SizedBox.square(
                    dimension: AppIconSize.md,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onSecondary,
                    ),
                  )
                : Text(l10n.onboardingContinue),
          ),
          const SizedBox(height: AppSpacing.xl),
          const CoverageNotice(),
        ],
      ),
    );
  }
}
