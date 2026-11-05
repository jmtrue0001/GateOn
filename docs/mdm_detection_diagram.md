# 타사 MDM 차단 판별 기술 모식도

## 핵심 원리

> **카메라가 제한(restricted)되어 있는데 "자사(GateON)가 막았다"는 근거가 없으면 → 타사 MDM 차단으로 판별한다.**

- OS는 "어느 앱이 카메라를 막았는지"를 직접 알려주지 않는다.
- 그래서 **① 하드웨어 제한 신호**와 **② 자사 제어 근거**를 조합해 추론한다.
- iOS·Android 모두 동일한 논리이며, "자사 근거"를 확인하는 수단만 플랫폼별로 다르다.
- 판별은 전부 **온-디바이스(단말 내부)** 에서 수행되며 **관리서버를 조회하지 않는다.**

| 구분 | iOS | Android |
|---|---|---|
| 카메라 차단 확인 | `AVCaptureDevice`(.restricted) | Knox `isCameraEnabled` 부정 |
| "자사가 막았나" 근거 | 자사 프로파일 **인증서 신뢰 평가** | **관리자 활성**(isAdminActive) + **차단 의도값**(profile_status) |
| 타사 판정 | 카메라 제한 ∧ 프로파일 미확인 | 카메라 제한 ∧ 의도 ≠ 'disable' |
| 데이터 출처 | 온-디바이스 (서버 X) | 온-디바이스 (서버 X) |
| 조회 실패 시 | false(미설치 간주) → 안전측 타사 판정 | Knox 미지원 에러 / 관리자 없으면 비제한 처리 |

---

## iOS — 인증서 신뢰 평가 방식

- **클래스**: `AppDelegate` (`ios/Runner/AppDelegate.swift`)
- **함수**: `getCameraBlockSource() -> [String: Any]`, `isMobileConfigInstalled() -> Bool`

### 흐름도

```
[①] 카메라 권한 조회
    AVCaptureDevice.authorizationStatus(for: .video)   → AVAuthorizationStatus
            │
            ▼
[②] 정책 제한인가?   status == .restricted ?
    (.denied=사용자 거부는 제외, 정책 제한만 차단으로 본다)
            │
      ┌─────┴───────────────┐
      │ NO (제한 아님)       │ YES (제한됨)
      ▼                     ▼
 ┌─────────┐        [③] 자사 프로파일 확인
 │ none    │            isMobileConfigInstalled() → Bool
 │ 차단없음 │                    │
 └─────────┘         (내부: 번들 leaf.cer 로드 → SecCertificateCreateWithData
                      → SecPolicyCreateBasicX509 → SecTrustCreateWithCertificates
                      → SecTrustEvaluateWithError [X.509 신뢰 평가])
                                  │
                      ┌───────────┴────────────┐
                      │ 신뢰 O (true)           │ 신뢰 X (false)
                      ▼                        ▼
                 ┌──────────┐            ┌──────────────┐
                 │ GateON   │            │ otherMdm     │
                 │ 자사 차단 │            │ 타사 MDM 차단 │
                 └──────────┘            └──────────────┘
```

### 항목 정리

| 항목 | 값 |
|---|---|
| 카메라 활성/차단 확인 | `AVCaptureDevice.authorizationStatus(for: .video)` → `AVAuthorizationStatus` |
| 차단(제한) 판정값 | `status == .restricted` → `isCameraRestricted = true` |
| 자기 정책 미적용 판단값 | `isMobileConfigInstalled() == false` (인증서 신뢰 실패 = 프로파일 미설치) |
| 타 MDM 판정 조건식 | `isCameraRestricted == true && gateOnProfileInstalled == false` → `"otherMdm"` |
| 자사 차단 조건식 | `isCameraRestricted == true && gateOnProfileInstalled == true` → `"GateON"` |
| 자기 프로파일 인증 확인 방식 | `leaf.cer` 로드 → `SecCertificateCreateWithData` → `SecPolicyCreateBasicX509` → `SecTrustCreateWithCertificates` → **`SecTrustEvaluateWithError`** |
| 앱 직접 조회 / 서버 확인 | **앱 직접 조회 (온-디바이스)** |
| 조회 실패·권한 부족 시 | 인증서 부재/로드 실패/생성 실패/평가 실패 → **모두 `return false`(미설치 간주)** → 카메라 제한 시 **타사로 안전측 판정** |
| 반환 필드 | `{ gateOnProfileInstalled: Bool, cameraRestricted: Bool, blockSource: "none"/"GateON"/"otherMdm" }` |

---

## Android — Knox 관리자·의도값 방식

- **클래스**: `MainActivity` (`MainActivity.kt`), Dart 래퍼 `AndroidMethodChannel` (`android_channel.dart`)
- **함수**: 네이티브 `getCameraStatus() -> Boolean`, 채널 `check_camera` / `check_admin` / Dart `checkCameraStatus() -> Future<bool>`

### 흐름도

```
[①] 자사 관리자 여부
    devicePolicyManager.isAdminActive(componentName)   → Boolean
            │
            ▼
[②] 카메라 상태 (Knox)
    차단 = !restrictionPolicy.isCameraEnabled(false)
    check_camera = getCameraStatus() && isAdminActive  → restricted
            │
            ▼
[③] 자사 차단 의도인가?   restricted && profile_status != 'disable' ?
    (profile_status = 로컬 저장 차단 의도: disable / enable / wait)
            │
   ┌────────┼───────────────────────────┐
   │        │                           │
   ▼        ▼                           ▼
NOT       restricted &                restricted &
restricted 의도=='disable'            의도!='disable'
   │        │                           │
   ▼        ▼                           ▼
┌───────┐ ┌──────────┐            ┌──────────────┐
│ none  │ │ GateON   │            │ otherMdm     │
│차단없음│ │ 자사 차단 │            │ 타사 MDM 차단 │
└───────┘ └──────────┘            └──────────────┘
```

### 항목 정리

| 항목 | 값 |
|---|---|
| 카메라 활성/차단 확인 | `restrictionPolicy.isCameraEnabled(false)` → `Boolean`, 차단 판정 = 그 부정(`!`) |
| 차단(제한) 값 | `getCameraStatus() == true` = 카메라 차단됨 |
| 자기 정책 미적용 판단값 | ① `isAdminActive(componentName) == false` (자사 관리자 아님) ② `profile_status != 'disable'` (자사 차단 의도 아님) |
| 타 MDM 판정 조건식 | (bloc) `cameraPermissionStatus == restricted && profile_status != 'disable'` → 타사 MDM |
| 자사 차단 조건식 | `restricted && profile_status == 'disable'` → GateON |
| 자기 정책 확인 방식 | `isAdminActive()`(관리자 활성 **직접 조회**) + 로컬 `profile_status`(차단 의도) 조합 |
| 앱 직접 조회 / 서버 확인 | **앱 직접 조회 (온-디바이스)** |
| 조회 실패·권한 부족 시 | Knox 미지원: `EnterpriseDeviceManager.getInstance()` → `NoClassDefFoundError` → "Samsung Knox를 지원하지 않는 기기입니다" / 관리자 미활성: `check_camera`의 `&& isAdminActive`가 false → 제한 신호 안 잡힘 / Dart 래퍼: `PlatformException` → `rethrow` |

---

## 분기별 동작

### 1. 자사 차단 · `GateON`
- **조건**: (iOS) restricted ∧ 프로파일O · (Android) restricted ∧ 의도=='disable'
- **동작**: 정상 차단 흐름을 그대로 유지. 자사 차단 UI 표시, 서버에 차단/해제 완료 기록.
- 사용자에겐 우리 앱의 차단 화면이 정상적으로 보인다.

### 2. 타사 MDM 차단 · `otherMdm`
- **조건**: 카메라 제한됨 ∧ 자사 근거 없음
- **동작**: 자사 차단 화면(붉은 화면) 대신 **"다른 보안앱(MDM)에서 카메라가 차단 중"** 안내로 전환. 상태를 `otherMdm`으로 두어 **비정상(위반) 처리에서 제외**.
- 목적: 자사가 막지 않은 것을 자사 차단/비정상으로 오인하지 않게 함.

### 3. 차단 없음 · `none`
- **조건**: 카메라 정상(restricted 아님)
- **동작**: 판별 종료, 정상 상태 유지, 별도 안내 없음. 이후 틱마다 재평가.

### 4. 예외 · 조회 실패 / 권한 부족
- **iOS**: 인증 확인 실패 → `false`(미설치)로 보아, 카메라 제한 시 **타사로 안전측 판정**.
- **Android**: Knox 미지원 기기는 지원 불가 에러 반환. 관리자 미활성이면 제한 신호 자체가 안 잡혀 **오탐을 만들지 않음**.

---

## 근거 코드
- iOS: `ios/Runner/AppDelegate.swift` — `getCameraBlockSource`, `isMobileConfigInstalled`
- Android: `android/app/src/main/kotlin/com/laonstory/mguard/MainActivity.kt` — `getCameraStatus`, `check_camera`, `isAdminActive`
- 판정 조합: `lib/features/home/bloc/home_bloc.dart`
