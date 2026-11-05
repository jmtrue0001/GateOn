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


    // 캡쳐 방지 코드
    self.window?.makeSecure()

    // ✅ Method Channel 설정
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let mobileConfigChannel = FlutterMethodChannel(name: "mguard/ios/mobileconfig",
                                                    binaryMessenger: controller.binaryMessenger)

    mobileConfigChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isMobileConfigInstalled":
        let isInstalled = self?.isMobileConfigInstalled() ?? false
        result(isInstalled)

      case "getProfileStatus":
        // 설치 여부(Bool)뿐 아니라 "인증서 조회 오류(앱 결함)"까지 구분해 반환한다.
        // status: "installed" | "not_installed" | "error"
        result(self?.getProfileStatus() ?? ["status": "error", "reason": "self is nil"])

      case "getCameraBlockSource":
        let blockInfo = self?.getCameraBlockSource() ?? [:]
        result(blockInfo)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ 프로파일 상태를 "설치/미설치/오류"로 구분해 반환한다.
  //   - installed     : 인증서 신뢰 성공 = 프로파일 설치됨
  //   - not_installed : 신뢰 평가는 정상 수행됐으나 미신뢰 = 프로파일 미설치 (정상 케이스)
  //   - error         : 앱 내장 인증서 파일 부재/로드 실패/객체 생성 실패 등 "앱 자체 결함" (사용자 안내 필요)
  func getProfileStatus() -> [String: Any] {
    // 1. 앱 번들에서 Leaf 인증서 파일 경로
    guard let certPath = Bundle.main.path(forResource: "leaf", ofType: "cer") else {
        return ["status": "error", "reason": "cert_file_missing"]
    }
    // 2. 인증서 데이터 로드
    guard let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath)) else {
        return ["status": "error", "reason": "cert_data_load_failed"]
    }
    // 3. SecCertificate 생성
    guard let cert = SecCertificateCreateWithData(nil, certData as CFData) else {
        return ["status": "error", "reason": "cert_create_failed"]
    }
    // 4~5. 신뢰 객체 생성
    let policy = SecPolicyCreateBasicX509()
    var trust: SecTrust?
    let status = SecTrustCreateWithCertificates(cert as CFTypeRef, policy, &trust)
    guard status == errSecSuccess, let validTrust = trust else {
        return ["status": "error", "reason": "trust_create_failed(\(status))"]
    }
    // 6. 신뢰 평가 — 여기서의 성공/실패는 "설치/미설치"라는 정상 판정이다.
    var error: CFError?
    let isValid = SecTrustEvaluateWithError(validTrust, &error)
    return ["status": isValid ? "installed" : "not_installed"]
  }

  // ✅ Mobile Config 설치 여부 확인 함수 (인증서 기반) — 기존 호출부 호환용 Bool 반환
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

  // ✅ 카메라 차단 출처 확인 함수
  func getCameraBlockSource() -> [String: Any] {
    // 1. TPASS 프로파일 설치 여부 (인증서 신뢰 기반)
    let gateOnProfileInstalled = isMobileConfigInstalled()

    // 2. 카메라 실제 사용 가능 여부 (AVFoundation)
    let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    let isCameraRestricted = (cameraStatus == .restricted)

    // 3. 차단 출처 판별
    var blockSource = "none"
    if isCameraRestricted {
        if gateOnProfileInstalled {
            blockSource = "GateON"
            print("📱 카메라 차단 출처: GateON")
        } else {
            blockSource = "otherMdm"
            print("📱 카메라 차단 출처: 다른 MDM")
        }
    } else {
        print("📱 카메라 차단 없음")
    }

    return [
        "gateOnProfileInstalled": gateOnProfileInstalled,
        "cameraRestricted": isCameraRestricted,
        "blockSource": blockSource
    ]
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


