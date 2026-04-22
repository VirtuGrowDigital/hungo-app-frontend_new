import Flutter
import FirebaseAuth
import FirebaseCore
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let mapConfigChannel = "hungzo_app/map_config"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

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

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      return true
    }

    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification notification: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(notification) {
      completionHandler(.noData)
      return
    }

    completionHandler(.noData)
  }

  private func hasMapsApiKey() -> Bool {
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String
    else {
      return false
    }

    return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
