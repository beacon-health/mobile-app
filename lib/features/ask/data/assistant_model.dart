import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the phone's own language model can be used right now.
enum AssistantAvailability {
  /// Not asked yet.
  unknown,

  /// This phone can't run the model, now or later. The Ask tab is hidden.
  unsupported,

  /// The phone can run it, but it isn't ready: still downloading, or turned
  /// off in the phone's settings.
  notReady,

  /// The phone can run it, but not in the app's current language.
  unsupportedLanguage,

  available,
}

/// The on-device language model, reduced to the one thing Ask needs from it:
/// reading a request into filters. It runs entirely on the phone; nothing is
/// sent anywhere.
///
/// It is deliberately not asked to write anything the person reads. Tried
/// against the real models, a sentence "summarizing" the results misnamed
/// facilities and said places were open that weren't; everything on screen
/// comes from the facility records instead.
abstract class AssistantModel {
  /// Whether the model can be used with the app in [languageCode].
  Future<AssistantAvailability> availability(String languageCode);

  /// Asks for the filters JSON described by `AskPrompts.filterInstructions`.
  /// May return anything, including nonsense; `AskRequest.parse` decides what
  /// to keep.
  Future<String> extractFilters({
    required String instructions,
    required String prompt,
  });
}

/// Which model Beacon uses on each platform. Like the sign-in provider, the
/// rule lives in one function that takes the platform, so both sides are
/// testable:
///
/// * iOS — Apple's Foundation Models framework (the Apple Intelligence
///   model), with guided generation for the filters.
/// * Android — Gemini Nano through ML Kit's GenAI Prompt API.
///
/// Anything else has no model, and no Ask tab.
abstract final class AssistantModelService {
  static AssistantModel? forPlatform(
    TargetPlatform platform, {
    bool isWeb = kIsWeb,
  }) {
    if (isWeb) return null;
    return switch (platform) {
      TargetPlatform.iOS ||
      TargetPlatform.android =>
        const MethodChannelAssistantModel(),
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows =>
        null,
    };
  }
}

/// Talks to the native bridge (`AssistantBridge` in the iOS and Android
/// projects). The channel carries the same two calls on both platforms.
class MethodChannelAssistantModel implements AssistantModel {
  const MethodChannelAssistantModel();

  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'org.beaconhealth.app/assistant',
  );

  @override
  Future<AssistantAvailability> availability(String languageCode) async {
    final status = await channel.invokeMethod<String>(
      'availability',
      {'locale': languageCode},
    );
    return switch (status) {
      'available' => AssistantAvailability.available,
      'notReady' => AssistantAvailability.notReady,
      'unsupportedLanguage' => AssistantAvailability.unsupportedLanguage,
      _ => AssistantAvailability.unsupported,
    };
  }

  @override
  Future<String> extractFilters({
    required String instructions,
    required String prompt,
  }) async {
    final text = await channel.invokeMethod<String>(
      'extractFilters',
      {'instructions': instructions, 'prompt': prompt},
    );
    return text ?? '';
  }
}
