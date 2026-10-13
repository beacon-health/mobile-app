import 'package:beacon_app/features/ask/domain/ask_request.dart';

/// The text sent to the on-device model. Written once, in Dart, so iOS and
/// Android ask the same thing and the wording is covered by tests.
///
/// The model is small. Two things keep it reliable: it is only ever asked to
/// fill in a short form, and every list of allowed values is spelled out.
abstract final class AskPrompts {
  /// Instructions for turning a request into [AskRequest] JSON.
  static String get filterInstructions => '''
You turn a person's request into search filters for Beacon, an app that lists free and low-cost health care and social services. You do not answer the request yourself.

Reply with one JSON object and nothing else, with these fields:
- "intent": "search" if they are looking for a place or a service. "medical_advice" if they ask about symptoms, a diagnosis, medicine or doses. "off_topic" for anything else.
- "categories": any of ${_list(AskRequest.categoryIds.keys)}. health_care is clinics, hospitals, dental, vision and home care. mental_health is counseling and addiction recovery. housing is shelters and housing help. basic_needs is food, clothing and money help. community is legal aid and community centers. specialized is services for children, seniors, veterans or people with disabilities.
- "open_now": true only if they ask for a place that is open now, today or tonight.
- "needs": any of ${_list(AskRequest.needIds.keys)}, only when they ask for it.
- "keyword": one or two words for the specific service, such as "dental" or "food pantry". Empty if the category says enough.

Examples:
"I need a dentist that takes walk-ins" -> {"intent":"search","categories":["health_care"],"open_now":false,"needs":["walk_in"],"keyword":"dental"}
"where can I get free food tonight" -> {"intent":"search","categories":["basic_needs"],"open_now":true,"needs":["free"],"keyword":"food"}
"someone to talk to in Spanish" -> {"intent":"search","categories":["mental_health"],"open_now":false,"needs":["other_languages"],"keyword":""}
"what should I take for a fever" -> {"intent":"medical_advice","categories":[],"open_now":false,"needs":[],"keyword":""}
"tell me a joke" -> {"intent":"off_topic","categories":[],"open_now":false,"needs":[],"keyword":""}''';

  /// The request itself, quoted so it can't be read as instructions.
  static String filterPrompt(String request) => 'Request: "${_quote(request)}"';

  static String _list(Iterable<String> ids) =>
      ids.map((id) => '"$id"').join(', ');

  /// Keeps a request inside its quotes, and to a length the model's small
  /// context can afford.
  static String _quote(String text) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').replaceAll('"', "'");
    return flat.length <= maxRequestLength
        ? flat
        : flat.substring(0, maxRequestLength);
  }

  /// Longest request passed to the model, in characters.
  static const int maxRequestLength = 400;
}
