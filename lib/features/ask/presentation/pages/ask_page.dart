import 'dart:async';

import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/empty_state.dart';
import 'package:beacon_app/features/ask/data/assistant_model.dart';
import 'package:beacon_app/features/ask/data/assistant_service.dart';
import 'package:beacon_app/features/ask/domain/ask_prompts.dart';
import 'package:beacon_app/features/ask/domain/ask_request.dart';
import 'package:beacon_app/features/ask/presentation/ask_controller.dart';
import 'package:beacon_app/features/ask/presentation/widgets/ask_messages.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// The Ask tab: say what you need in your own words, and get places back.
///
/// The phone's own language model reads the request; nothing leaves the
/// device. It only ever picks filters — the places, and every word about
/// them, come from the same query as the Map, and whenever Ask can't answer
/// it hands the request to the Map rather than guessing (see
/// [AskController]).
class AskPage extends StatefulWidget {
  const AskPage({
    super.key,
    required this.onOpenMap,
    required this.onShowFacility,
  });

  /// Opens the Map tab with [AskFilters] applied.
  final ValueChanged<AskFilters> onOpenMap;

  /// Opens one facility on the Map tab.
  final ValueChanged<Facility> onShowFacility;

  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  AskController? _controller;
  AssistantModel? _controllerModel;

  @override
  void dispose() {
    _controller?.removeListener(_onConversationChanged);
    _controller?.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The controller for the phone's model, made once it is known.
  AskController? _controllerFor(AssistantModel? model) {
    if (model == null) return null;
    if (_controller != null && identical(model, _controllerModel)) {
      return _controller;
    }
    _controller?.removeListener(_onConversationChanged);
    _controller?.dispose();
    _controllerModel = model;
    return _controller = AskController(
      model: model,
      repository: context.read<FacilityRepositoryBase>(),
    )..addListener(_onConversationChanged);
  }

  void _onConversationChanged() {
    if (!mounted) return;
    setState(() {});
    // Keep the newest message in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (AppMotion.reduced(context)) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: AppMotion.medium,
          curve: AppMotion.curve,
        );
      }
    });
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    unawaited(_controller?.send(text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final assistant = context.watch<AssistantService>();
    final controller =
        assistant.isReady ? _controllerFor(assistant.model) : null;
    final hasMessages = controller != null && controller.messages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.askTitle),
        actions: [
          if (hasMessages)
            IconButton(
              tooltip: l10n.askNewChat,
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: controller.clear,
            ),
        ],
      ),
      body: controller == null
          ? _buildUnavailable(l10n, assistant.availability)
          : _buildConversation(l10n, controller),
    );
  }

  /// The model exists but can't be used right now: say so, and offer the Map.
  Widget _buildUnavailable(
    AppLocalizations l10n,
    AssistantAvailability availability,
  ) {
    final wrongLanguage =
        availability == AssistantAvailability.unsupportedLanguage;
    return Center(
      child: SingleChildScrollView(
        child: EmptyState(
          icon: wrongLanguage ? Icons.translate : Icons.hourglass_empty,
          title: wrongLanguage ? l10n.askLanguageTitle : l10n.askNotReadyTitle,
          message: wrongLanguage ? l10n.askLanguageBody : l10n.askNotReadyBody,
          action: FilledButton.icon(
            onPressed: () => widget.onOpenMap(const AskFilters()),
            icon: const Icon(Icons.map_outlined),
            label: Text(l10n.askSearchMap),
          ),
        ),
      ),
    );
  }

  Widget _buildConversation(AppLocalizations l10n, AskController controller) {
    final theme = Theme.of(context);
    final messages = controller.messages;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: [
              if (messages.isEmpty)
                _buildStart(l10n, controller)
              else
                for (final (index, message) in messages.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.lg),
                  _buildMessage(message, controller),
                ],
              if (controller.isThinking) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const SizedBox.square(
                      dimension: AppIconSize.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(l10n.askThinking, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ],
            ],
          ),
        ),
        _buildInput(l10n, controller),
      ],
    );
  }

  /// Before the first message: what Ask is for, four ways in, and where to
  /// turn in an emergency.
  Widget _buildStart(AppLocalizations l10n, AskController controller) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final suggestions = [
      (
        l10n.askSuggestionClinic,
        FacilityCategories.groupHealthCare,
        const AskFilters(
          groups: {FacilityCategories.groupHealthCare},
          preferences: {PreferenceRequirement.freeServicesAvailable},
        ),
      ),
      (
        l10n.askSuggestionTalk,
        FacilityCategories.groupMentalHealth,
        const AskFilters(groups: {FacilityCategories.groupMentalHealth}),
      ),
      (
        l10n.askSuggestionFood,
        FacilityCategories.groupBasicNeeds,
        const AskFilters(
          groups: {FacilityCategories.groupBasicNeeds},
          openNow: true,
          keyword: 'food',
        ),
      ),
      (
        l10n.askSuggestionShelter,
        FacilityCategories.groupHousingShelter,
        const AskFilters(groups: {FacilityCategories.groupHousingShelter}),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(l10n.askHeading, style: theme.textTheme.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final (label, group, filters) in suggestions) ...[
          _SuggestionButton(
            label: label,
            group: group,
            onTap: () => unawaited(
              controller.search(label, filters),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.emergency_outlined, size: AppIconSize.md, color: muted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.askCrisisNote,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessage(AskMessage message, AskController controller) {
    switch (message) {
      case AskUserMessage(:final text):
        return AskUserBubble(text: text);
      case AskCrisisMessage():
        return const AskCrisisCard();
      case AskAnswerMessage(:final filters):
        return AskAnswer(
          message: message,
          onShowFacility: widget.onShowFacility,
          onShowOnMap: () => widget.onOpenMap(filters),
          onOnlyOpenNow: filters.openNow || message.noneOpenNow
              ? null
              : () => unawaited(
                    controller.search(
                      AppLocalizations.of(context)!.askOnlyOpenNow,
                      filters.copyWith(openNow: true),
                    ),
                  ),
        );
      case AskHandoffMessage(:final filters):
        return AskHandoff(
          message: message,
          onOpenMap: () => widget.onOpenMap(filters),
        );
    }
  }

  Widget _buildInput(AppLocalizations l10n, AskController controller) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AskPrompts.maxRequestLength,
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.askInputLabel,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    tooltip: l10n.askSend,
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: controller.isThinking ? null : _send,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.askPrivacyFooter,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the four ways in: a category's icon and a request in plain words.
class _SuggestionButton extends StatelessWidget {
  const _SuggestionButton({
    required this.label,
    required this.group,
    required this.onTap,
  });

  final String label;
  final String group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = MarkerUtils.getColorForCategory(
      group,
      brightness: theme.brightness,
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTouchTarget + AppSpacing.sm,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // The color is the icon's; the words stay in the text color.
                Icon(MarkerUtils.getIconForCategory(group), color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
