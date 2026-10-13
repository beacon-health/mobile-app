import Flutter
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// The Ask tab's bridge to Apple's on-device language model (the Foundation
/// Models framework, iOS 26 and later on phones with Apple Intelligence).
/// Nothing is sent off the device.
///
/// The Dart side (`MethodChannelAssistantModel`) writes every prompt; this
/// only reports whether the model can be used and runs what it is given.
/// Android has the same two calls over Gemini Nano.
enum AssistantBridge {
  static let channelName = "org.beaconhealth.app/assistant"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let arguments = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "availability":
        result(availability(languageCode: arguments["locale"] as? String ?? "en"))
      case "extractFilters":
        guard let instructions = arguments["instructions"] as? String,
          let prompt = arguments["prompt"] as? String
        else {
          result(
            FlutterError(
              code: "bad_arguments", message: "instructions and prompt are required",
              details: nil))
          return
        }
        extractFilters(instructions: instructions, prompt: prompt, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// "available", "notReady" (the phone can run the model, but it is still
  /// downloading or Apple Intelligence is switched off), "unsupportedLanguage"
  /// or "unsupported".
  private static func availability(languageCode: String) -> String {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      let model = SystemLanguageModel.default
      switch model.availability {
      case .available:
        return model.supportsLocale(Locale(identifier: languageCode))
          ? "available" : "unsupportedLanguage"
      case .unavailable(.deviceNotEligible):
        return "unsupported"
      case .unavailable:
        return "notReady"
      @unknown default:
        return "notReady"
      }
    }
    #endif
    return "unsupported"
  }

  private static func extractFilters(
    instructions: String, prompt: String, result: @escaping FlutterResult
  ) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      Task { @MainActor in
        do {
          // A new session per request: Ask keeps its own history, and the
          // model's small context is better spent on the request.
          let session = LanguageModelSession(instructions: instructions)
          // Guided generation: the model can only produce this shape, so the
          // reply is always valid. Greedy sampling, so the same request reads
          // the same way every time.
          let response = try await session.respond(
            to: prompt, generating: AssistantFilters.self,
            options: GenerationOptions(sampling: .greedy))
          result(response.content.json)
        } catch {
          // A guardrail, an unsupported language, a full context: Dart treats
          // every failure the same way, by handing the request to the Map.
          result(
            FlutterError(
              code: "generation_failed", message: String(describing: error), details: nil))
        }
      }
      return
    }
    #endif
    result(FlutterError(code: "unsupported", message: "No on-device model", details: nil))
  }
}

#if canImport(FoundationModels)
/// The filters a request turns into. Mirrors `AskRequest` in Dart; the ids in
/// `json` are the ones its parser accepts.
@available(iOS 26.0, *)
@Generable
struct AssistantFilters {
  @Generable
  enum Intent {
    case search
    case medicalAdvice
    case offTopic
  }

  @Generable
  enum Category {
    case healthCare
    case mentalHealth
    case housing
    case basicNeeds
    case community
    case specialized
  }

  @Generable
  enum Need {
    case free
    case slidingScale
    case walkIn
    case telehealth
    case wheelchair
    case otherLanguages
    case immigrants
  }

  @Guide(
    description:
      "search if they are looking for a place or service; medicalAdvice if they ask about symptoms, a diagnosis, medicine or doses; offTopic for anything else"
  )
  var intent: Intent

  @Guide(description: "The kinds of service that fit the request. Empty if none clearly does.")
  var categories: [Category]

  @Guide(description: "True only if they ask for a place open now, today or tonight")
  var openNow: Bool

  @Guide(description: "Only what the request explicitly asks for")
  var needs: [Need]

  @Guide(
    description:
      "One or two words for the specific service, such as dental or food pantry. Empty if the category says enough."
  )
  var keyword: String

  var json: String {
    let intentId: String
    switch intent {
    case .search: intentId = "search"
    case .medicalAdvice: intentId = "medical_advice"
    case .offTopic: intentId = "off_topic"
    }
    let categoryIds: [String] = categories.map {
      switch $0 {
      case .healthCare: return "health_care"
      case .mentalHealth: return "mental_health"
      case .housing: return "housing"
      case .basicNeeds: return "basic_needs"
      case .community: return "community"
      case .specialized: return "specialized"
      }
    }
    let needIds: [String] = needs.map {
      switch $0 {
      case .free: return "free"
      case .slidingScale: return "sliding_scale"
      case .walkIn: return "walk_in"
      case .telehealth: return "telehealth"
      case .wheelchair: return "wheelchair"
      case .otherLanguages: return "other_languages"
      case .immigrants: return "immigrants"
      }
    }
    let object: [String: Any] = [
      "intent": intentId,
      "categories": categoryIds,
      "open_now": openNow,
      "needs": needIds,
      "keyword": keyword,
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: object),
      let text = String(data: data, encoding: .utf8)
    else { return "{}" }
    return text
  }
}
#endif
