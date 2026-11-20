import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var sizeClassChannel: FlutterMethodChannel?
  private var deferredSizeClassRegistration = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerSizeClassChannel()
    return launched
  }

  /// 用现有的 FlutterViewController 读水平 size class。控制器还没挂上时，只再等一轮 runloop。
  private func registerSizeClassChannel() {
    if sizeClassChannel != nil { return }
    guard let controller = window?.rootViewController as? FlutterViewController else {
      if deferredSizeClassRegistration { return }
      deferredSizeClassRegistration = true
      DispatchQueue.main.async { [weak self] in
        self?.registerSizeClassChannel()
      }
      return
    }
    let channel = FlutterMethodChannel(
      name: "digi_players/size_class",
      binaryMessenger: controller.binaryMessenger
    )
    sizeClassChannel = channel
    channel.setMethodCallHandler { [weak controller] call, result in
      switch call.method {
      case "getHorizontalSizeClass":
        guard let controller else {
          result("unspecified")
          return
        }
        switch controller.traitCollection.horizontalSizeClass {
        case .compact:
          result("compact")
        case .regular:
          result("regular")
        default:
          result("unspecified")
        }
      case "getFoldDivision":
        // 当前系统没有折痕接口。不活跃时宽高为 0，Flutter 继续用步骤 1 到 6 的布局。
        result([
          "active": false,
          "left": 0.0,
          "top": 0.0,
          "width": 0.0,
          "height": 0.0,
        ] as [String: Any])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
