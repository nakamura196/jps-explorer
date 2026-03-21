import Flutter
import UIKit
import CoreSpotlight

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.nakamura196.jpsExplorer/spotlight",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "indexItem":
          guard let args = call.arguments as? [String: Any],
                let id = args["id"] as? String,
                let title = args["title"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
            return
          }
          let attributeSet = CSSearchableItemAttributeSet(itemContentType: "public.content")
          attributeSet.title = title
          attributeSet.contentDescription = args["description"] as? String
          attributeSet.keywords = args["keywords"] as? [String]
          if let thumbUrl = args["thumbnailUrl"] as? String, let url = URL(string: thumbUrl) {
            attributeSet.thumbnailURL = url
          }
          let item = CSSearchableItem(
            uniqueIdentifier: id,
            domainIdentifier: "com.nakamura196.jpsExplorer.items",
            attributeSet: attributeSet
          )
          item.expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
          CSSearchableIndex.default().indexSearchableItems([item]) { error in
            result(error == nil)
          }

        case "removeItem":
          guard let id = call.arguments as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing ID", details: nil))
            return
          }
          CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id]) { error in
            result(error == nil)
          }

        case "removeAll":
          CSSearchableIndex.default().deleteAllSearchableItems { error in
            result(error == nil)
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
