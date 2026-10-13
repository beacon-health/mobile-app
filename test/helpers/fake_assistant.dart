import 'dart:async';

import 'package:beacon_app/features/ask/data/assistant_model.dart';
import 'package:beacon_app/features/ask/data/assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The phone's language model, for tests: says what it is told to say and
/// records what it was asked.
class FakeAssistantModel implements AssistantModel {
  FakeAssistantModel({this.status = AssistantAvailability.available});

  AssistantAvailability status;

  /// What `extractFilters` replies. Reassign per test.
  String filtersReply = '{}';

  /// Thrown in place of a reply, when set.
  Object? filtersError;

  /// While set, replies wait on it — for holding Ask in "Looking…".
  Completer<void>? gate;

  /// Every prompt received, oldest first.
  final List<String> filterPrompts = [];
  final List<String> filterInstructions = [];

  @override
  Future<AssistantAvailability> availability(String languageCode) async =>
      status;

  @override
  Future<String> extractFilters({
    required String instructions,
    required String prompt,
  }) async {
    filterInstructions.add(instructions);
    filterPrompts.add(prompt);
    await gate?.future;
    if (filtersError case final error?) throw error;
    return filtersReply;
  }
}

/// Gives the test's "phone" a language model in [status]. Call it after
/// `resetAppState`, which takes the model away.
Future<FakeAssistantModel> useAssistant({
  AssistantAvailability status = AssistantAvailability.available,
}) async {
  final model = FakeAssistantModel(status: status);
  final service = AssistantService()
    ..debugReset()
    ..debugModel = model;
  addTearDown(service.debugReset);
  await service.refresh();
  return model;
}
