import Flutter
import GoogleMaps
import UIKit
import os

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Runs before the scene connects and creates the Flutter view, so the
    // Maps SDK has its key before any map exists. The key comes from the
    // gitignored ios/Flutter/Secrets.xcconfig via Info.plist; without it the
    // map renders blank but the app still runs.
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? ""
    if apiKey.isEmpty || apiKey.hasPrefix("$(") {
      os_log("GOOGLE_MAPS_API_KEY is not set; the map will be blank.", type: .error)
      GMSServices.provideAPIKey("")
    } else {
      GMSServices.provideAPIKey(apiKey)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene lifecycle: the scene's storyboard creates the Flutter engine
  // implicitly, and plugins register here once it exists.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
