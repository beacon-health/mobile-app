import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/facility_request_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/empty_state.dart';
import 'package:beacon_app/core/widgets/facility_request_dialog.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Lists the "add a facility" requests the signed-in user has submitted, with
/// their review status. Mirrors the Your Ratings page.
class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final FacilityRequestService _requestService = FacilityRequestService();

  bool _loading = true;
  List<FacilityRequestEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final entries = await _requestService.getMine();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'MyRequestsPage._load',
      );
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _newRequest() async {
    await showFacilityRequestDialog(context);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsYourRequests),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AppLocalizations.of(context)!.mapRequestFacility,
            onPressed: _newRequest,
          ),
        ],
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

  /// Status chip color: pending → secondary (gray), approved → primary
  /// (green), rejected → tertiary (bittersweet).
  Color _statusColor(String status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      'approved' => scheme.primary,
      'rejected' => scheme.tertiary,
      _ => scheme.secondary,
    };
  }

  Widget _buildRow(FacilityRequestEntry entry) {
    final color = _statusColor(entry.status);
    final l10n = AppLocalizations.of(context)!;
    final created = entry.createdAt;
    final parts = [
      if (entry.isCorrection)
        l10n.requestTypeCorrection
      else
        l10n.requestTypeNew,
      if (created != null)
        MaterialLocalizations.of(context).formatMediumDate(created),
    ].where((s) => s.isNotEmpty).join(' · ');

    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.tintStrong,
        child: Icon(
          entry.isCorrection
              ? Icons.edit_note_outlined
              : Icons.add_business_outlined,
          color: color,
          size: AppIconSize.md,
        ),
      ),
      title: Text(
        entry.facilityName,
        style: theme.textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: parts.isEmpty
          ? null
          : Text(
              parts,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: TagChip(label: entry.status, color: color),
    );
  }

  Widget _buildEmptyState() {
    // Wrapped in a scroll view so RefreshIndicator still works when empty.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: EmptyState(
              icon: Icons.add_business_outlined,
              title: AppLocalizations.of(context)!.requestsEmptyTitle,
              message: AppLocalizations.of(context)!.requestsEmptyHint,
              action: FilledButton.icon(
                onPressed: _newRequest,
                icon: const Icon(Icons.add, size: AppIconSize.md),
                label: Text(AppLocalizations.of(context)!.mapRequestFacility),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
