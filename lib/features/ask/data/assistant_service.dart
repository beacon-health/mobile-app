import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/features/ask/data/assistant_model.dart';
import 'package:flutter/foundation.dart';

/// Knows whether this phone has a language model Ask can use, and holds it.
/// The tab bar listens here to decide whether to show the Ask tab at all.
class AssistantService extends ChangeNotifier {
  factory AssistantService() => _instance;
  AssistantService._();
  static final AssistantService _instance = AssistantService._();

  /// Lets a test stand in for the phone's model.
  @visibleForTesting
  AssistantModel? debugModel;

  /// Set by tests that want a phone with no model at all.
  @visibleForTesting
  bool debugNoModel = false;

  AssistantAvailability _availability = AssistantAvailability.unknown;
  AssistantAvailability get availability => _availability;

  /// The platform's model, or null where there is none.
  AssistantModel? get model {
    if (debugNoModel) return null;
    return debugModel ??
        AssistantModelService.forPlatform(defaultTargetPlatform);
  }

  /// Whether the Ask tab is offered. A phone that can never run the model
  /// doesn't get a tab that could only ever say so; one that can, but isn't
  /// ready, gets the tab and an explanation.
  bool get showsTab => switch (_availability) {
        AssistantAvailability.unknown ||
        AssistantAvailability.unsupported =>
          false,
        AssistantAvailability.notReady ||
        AssistantAvailability.unsupportedLanguage ||
        AssistantAvailability.available =>
          true,
      };

  bool get isReady => _availability == AssistantAvailability.available;

  Future<void> init() => refresh();

  /// Asks the phone again: the model may have finished downloading, been
  /// switched on in Settings, or the app's language may have changed.
  Future<void> refresh() async {
    final next = await _ask();
    if (next == _availability) return;
    _availability = next;
    notifyListeners();
  }

  Future<AssistantAvailability> _ask() async {
    final model = this.model;
    if (model == null) return AssistantAvailability.unsupported;
    try {
      return await model.availability(LocaleProvider().locale.languageCode);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: 'AssistantService.refresh',
      );
      return AssistantAvailability.unsupported;
    }
  }

  @visibleForTesting
  void debugReset() {
    debugModel = null;
    debugNoModel = false;
    _availability = AssistantAvailability.unknown;
  }
}
