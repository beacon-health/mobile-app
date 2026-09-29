import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/coverage_notice.dart';
import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZipEntryPage extends StatefulWidget {
  const ZipEntryPage({super.key, this.prefilledZip});

  /// Optional ZIP to pre-populate the input. Used when returning a recently
  /// signed-in guest user back through the location flow.
  final String? prefilledZip;

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
    final success = await ZipCodeService().setZipCode(zip);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Couldn't find that zip code. Please try again.";
      });
      return;
    }

    // Signed-in users get the required Eligibility step next; guests go
    // straight to the app.
    finishLocationOnboarding(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.onboarding(context),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.onboardingGutter,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  l10n.zipEntryTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.zipEntrySubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '00000',
                    hintStyle: AppTypography.zipInput.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: AppOpacity.disabled,
                      ),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: AppRadii.smAll,
                      borderSide: BorderSide.none,
                    ),
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
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
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
                ),
                const SizedBox(height: AppSpacing.xl),
                const CoverageNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
