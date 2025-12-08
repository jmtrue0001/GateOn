import UIKit
import Flutter
import Security
import AVFoundation
import Foundation


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

    // ✅ Method Channel 설정
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let mobileConfigChannel = FlutterMethodChannel(name: "mguard/ios/mobileconfig",
                                                    binaryMessenger: controller.binaryMessenger)

    mobileConfigChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "isMobileConfigInstalled" {
        let isInstalled = self?.isMobileConfigInstalled() ?? false
        result(isInstalled)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ Mobile Config 설치 여부 확인 함수 (인증서 기반)
  func isMobileConfigInstalled() -> Bool {
    // 1. 앱 번들에서 Leaf 인증서 파일 경로를 찾습니다.
    guard let certPath = Bundle.main.path(forResource: "leaf", ofType: "cer") else {
        print("❌ LeafCertificate.cer 파일을 찾을 수 없습니다.")
        return false
    }

    // 2. 파일에서 인증서 데이터를 불러옵니다.
    guard let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath)) else {
        print("오류: 인증서 데이터를 불러올 수 없습니다.")
        return false
    }

    // 3. SecCertificateRef 생성 (Swift에서는 자동으로 관리되므로 CFTypeRef 대신 직접 사용)
    guard let cert = SecCertificateCreateWithData(nil, certData as CFData) else {
        print("오류: SecCertificateRef 생성 실패.")
        return false
    }

    // 4. X.509 기본 정책 생성
    let policy = SecPolicyCreateBasicX509()

    var trust: SecTrust?

    // 5. 인증서를 바탕으로 신뢰 객체(SecTrust) 생성
    let status = SecTrustCreateWithCertificates(cert as CFTypeRef, policy, &trust)

    guard status == errSecSuccess, let validTrust = trust else {
        print("오류: SecTrustCreateWithCertificates 실패 (상태 코드: \(status)).")
        return false
    }

    // 6. 신뢰 평가 실행 (iOS 12+)
    var error: CFError?
    let isValid = SecTrustEvaluateWithError(validTrust, &error)

    // Swift에서는 CFRelease를 명시적으로 호출할 필요가 없습니다. ARC가 메모리를 관리합니다.
    // 정책과 인증서 객체는 함수 범위를 벗어나면 자동으로 해제됩니다.

    print("📋 Trust evaluation result: \(isValid)")
    if let error = error {
        print("❌ Trust error: \(error)")
    }

    // 7. 결과 확인
    if isValid {
        print("✅ 인증서가 성공적으로 신뢰되었습니다 (프로필 설치됨).")
        return true
    } else {
        print("❌ 인증서 신뢰 실패 (프로필 미설치 또는 유효하지 않음).")
        return false
    }
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
