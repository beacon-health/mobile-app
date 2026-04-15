import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Initialize Google Maps
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
       !apiKey.isEmpty,
       !apiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(apiKey)
      print("✅ Google Maps initialized with API key")
    } else {
      print("⚠️ GOOGLE_MAPS_API_KEY not found in Info.plist or Secrets.xcconfig")
      print("   Create ios/Flutter/Secrets.xcconfig with: GOOGLE_MAPS_API_KEY=your_key_here")
      // Provide empty key to prevent crash - map won't work but app will run
      GMSServices.provideAPIKey("")
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
