# MGuard Project Structure
MGuard 프로젝트의 구조에 대한 문서입니다.

## 패키지 구조 
```yaml
environment:
  sdk: '>=3.0.3 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  #State manage
  equatable: ^2.0.5
  flutter_bloc: ^8.1.1
  bloc: ^8.1.0
  bloc_concurrency: ^0.2.0
  stream_transform: ^2.1.0

  #logic
  http: ^1.1.0
  flutter_secure_storage: ^6.1.0
  shared_preferences: ^2.0.17
  json_annotation: ^4.7.0
  url_launcher: ^6.1.10
  http_parser: ^4.0.2
  go_router: ^8.1.0
  copy_with_extension: ^5.0.3
  convert: ^3.1.1

  #view
  flutter_icon_snackbar: ^1.1.4
  flutter_icon_dialog: ^1.2.1
  icon_animated: ^1.2.1
  flutter_static_utility: ^1.0.2
  responsive_framework: ^0.2.0
  cupertino_icons: ^1.0.2
  flutter_svg: ^2.0.2
  cached_network_image: ^3.3.0
  flutter_html: ^3.0.0-beta.1
  auto_size_text: ^3.0.0
  fl_chart: ^0.61.0
  dotted_border: ^2.0.0+3
  blurrycontainer: ^1.0.2
  lottie: ^2.6.0
  flutter_spinkit: ^5.2.0
  simple_ripple_animation: ^0.0.7


  #util
  url_strategy: ^0.2.0
  logger: ^1.1.0
  intl: ^0.18.0
  device_info_plus: ^9.0.3
  package_info_plus: ^4.1.0
  permission_handler: ^8.3.0
  envied: ^0.3.0+3
  encrypt: ^5.0.1
  nfc_manager: ^3.3.0
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.4+2
  file_picker: ^5.3.3
  geolocator: ^10.0.0
  flutter_blue_plus: ^1.14.11
  android_intent_plus: ^4.0.3

  #firebase
  firebase_core: ^2.8.0
  firebase_performance: ^0.9.0+16
  firebase_crashlytics: ^3.0.17
  firebase_analytics: ^10.1.6

  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  source_gen: ^1.3.2
  build_runner: ^2.4.4
  json_serializable: ^6.5.4
  envied_generator: ^0.3.0+3
  copy_with_extension_gen: ^5.0.3
  change_app_package_name: ^1.1.0

flutter:
  uses-material-design: true

  assets:
    - assets/icons/
    - assets/images/

  fonts:
    - family: SUIT
      fonts:
        - asset: assets/fonts/SUIT-Thin.otf
          weight: 100
        - asset: assets/fonts/SUIT-ExtraLight.otf
          weight: 200
        - asset: assets/fonts/SUIT-Light.otf
          weight: 300
        - asset: assets/fonts/SUIT-Regular.otf
          weight: 400
        - asset: assets/fonts/SUIT-Medium.otf
          weight: 500
        - asset: assets/fonts/SUIT-Bold.otf
          weight: 700
        - asset: assets/fonts/SUIT-ExtraBold.otf
          weight: 800
        - asset: assets/fonts/SUIT-Heavy.otf
          weight: 900



```
하단의 내용을 숙지하여 `pubspec.yaml`을 작성합니다.
- 패키지의 경우 `pubspec.yaml` 파일을 참고하며, 문서에 명시된 버전에서 업데이트는 **제한**합니다.
- 단, `preRelease` 버전의 패키지의 경우에는 **테스트**를 거친 후 업데이트를 진행합니다.
- `flutter`의 경우에는 `3.16` 이상의 `stable` 버전을 사용합니다.
- `dart`의 경우에는 `3.0` 이상의 `stable` 버전을 사용합니다.
- 사용하는 패키지의 라이센스는 자동으로 `LicensePage.dart`에서 관리됩니다.
- 마지막으로, `firebase` 패키지의 버전을 매번 확인하여 관리합니다.
#### 패키지 버전 확인
```shell
flutter pub outdated
```
---
## 파일 구조
```
lib
├── core
|  ├── bloc
|  ├── channel
|  ├── config
|  ├── domain
|  ├── enum
|  ├── ui
|  ├── util
|  ├── widget
|  └── core.dart
|
├── features
|  ├── home
|  |    ├── bloc
|  |    ├── repository
|  |    └── ui
|  └── permission
|       ├── bloc
|       ├── ...
|  ├── ...
|
├── admin
|  ├── main
|  |    ├── bloc
|  |    ├── repository
|  |    └── ui
|  └── settings
|       ├── bloc
|       ├── ...
|  ├── ...
|
└── main.dart
```
파일 구조는 기본적으로 **Clean Architecture** 를 따릅니다.<br>
또한 파일 구조는 아래의 형식을 따라야합니다.
***
- `core` : 프로젝트의 핵심 기능을 담당하는 파일들을 저장합니다.
- `features` : 모바일 앱의 뷰와 기능을 담당하는 파일들을 저장합니다.
- `admin` : 관리자 앱의 뷰와 기능을 담당하는 파일들을 저장합니다.
***
- `bloc` : bloc 파일들을 저장합니다.
- `repository` : repository 파일들을 저장합니다.
- `ui` : ui 파일 (page)들을 저장합니다.
- `widget` : ui 파일 (widget)들을 저장합니다.




