import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let mapConfigChannel = "hungzo_app/map_config"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
       !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: mapConfigChannel,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "hasMapsApiKey" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(self?.hasMapsApiKey() ?? false)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func hasMapsApiKey() -> Bool {
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String
    else {
      return false
    }

    return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
