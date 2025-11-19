import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  var blurView: UIVisualEffectView?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ✅ 보안 화면 적용
    self.window?.makeSecure()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
      let blurEffect = UIBlurEffect(style: .light)
      blurView = UIVisualEffectView(effect: blurEffect)
      blurView?.frame = window?.bounds ?? .zero
      blurView?.tag = 9999
      if let blur = blurView {
        window?.addSubview(blur)
      }
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
      if let existingBlur = window?.viewWithTag(9999) {
        existingBlur.removeFromSuperview()
      }
      blurView = nil
    }
}

// ✅ UIWindow 확장 구현
extension UIWindow {
    func makeSecure() {
        let field = UITextField()
        field.isSecureTextEntry = true

        let secureView = UIView(frame: self.frame)
        secureView.backgroundColor = .clear

        self.addSubview(field)
        self.layer.superlayer?.addSublayer(field.layer)
        field.layer.sublayers?.last?.addSublayer(self.layer)

        field.leftView = secureView
        field.leftViewMode = .always
    }
}
// 캡쳐 방지 해제 코드
// import UIKit
// import Flutter
// import GoogleMaps
//
// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//       _ application: UIApplication,
//       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//     ) -> Bool {
//       GMSServices.provideAPIKey("AIzaSyBMVLlVWgDqjalM0mhUoGPtVBQQ_fylYGc")
//       GeneratedPluginRegistrant.register(with: self)
//       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//     }
// }
