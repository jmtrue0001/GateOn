import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' show Platform;

import 'package:GateON/core/core.dart';
import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';

import 'core/config/style.dart';

Future<void> main() async {
  logger.d('앱 진입점');
  AppConfig.init(
    callback: () async {
      if (kIsWeb) {
        logger.d('웹');
        runApp(DesktopWeb());
        return;
      }

      Bloc.observer = AppBlocObserver();
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await FirebaseCrashlytics.instance.setCustomKey('manufacturer', AppConfig.to.manufacturer ?? 'unknown');
      await FirebaseCrashlytics.instance.setCustomKey('model', AppConfig.to.model ?? 'unknown');
      await FirebaseCrashlytics.instance.setCustomKey('os_version', AppConfig.to.osVersion ?? 'unknown');
      await FirebaseCrashlytics.instance.setCustomKey('app_version', AppConfig.to.appVersion ?? 'unknown');
      // 인터넷 연결 감지 서비스 초기화
      await ConnectivityService.to.init();

      if (Platform.isAndroid) {
        final String? stored = await AppConfig.to.storage.read(key: 'deviceId');
        if (stored == null) {
          final String? id = await AndroidMethodChannel.to.getId();
          if (id != null) {
            await AppConfig.to.storage.write(key: "deviceId", value: id);
            logger.d("${id} 다바이스 id");
          }
        }
      } else if (Platform.isIOS) {
        var iosInfo = await AppConfig.to.deviceInfo.iosInfo;
        await AppConfig.to.storage.read(key: 'deviceId').then((value) async {
          if (value == null) {
            await AppConfig.to.storage.write(key: "deviceId", value: iosInfo.identifierForVendor);
          }
        });
      }

      runApp(App());
      return;
    },
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = AppRouter();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isDialogShowing = false;
  OverlayEntry? _noInternetOverlay;
  Timer? _disconnectDebounce;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // 인터넷 연결 상태 스트림 구독
    _startConnectivityListener();

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        logger.d('앱 포그라운드 전환 - 인터넷 감지 재시작');
        // iOS 네트워크 복구 대기 후 구독 재시작
        Future.delayed(const Duration(seconds: 3), _startConnectivityListener);
      },
      onPause: () {
        logger.d('앱 백그라운드 전환 - 인터넷 감지 일시중지');
        _disconnectDebounce?.cancel();
        _connectivitySubscription?.cancel();
        _connectivitySubscription = null;
      },
    );
  }

  void _startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = ConnectivityService.to.statusStream.listen((isConnected) {
      if (!isConnected) {
        // 3초간 끊김이 유지될 때만 다이얼로그 표시 (일시적 끊김 무시)
        _disconnectDebounce?.cancel();
        _disconnectDebounce = Timer(const Duration(seconds: 3), () {
          if (!_isDialogShowing) _showNoInternetDialog();
        });
      } else {
        _disconnectDebounce?.cancel();
        if (_isDialogShowing) _removeNoInternetOverlay();
      }
    });
  }

  Future<void> _checkCurrentConnection() async {
    final isConnected = await ConnectivityService.to.checkConnection();
    if (!isConnected && !_isDialogShowing) {
      _showNoInternetDialog();
    }
  }

  @override
  void dispose() {
    _disconnectDebounce?.cancel();
    _connectivitySubscription?.cancel();
    _lifecycleListener.dispose();
    _removeNoInternetOverlay();
    super.dispose();
  }

  void _showNoInternetDialog() {
    final context = navigatorKey.currentContext;
    if (context == null || _isDialogShowing) return;

    // Navigator의 root overlay 가져오기
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) {
      logger.d('Overlay를 찾을 수 없음');
      return;
    }

    _isDialogShowing = true;
    logger.d('인터넷 끊김 Overlay 표시');

    _noInternetOverlay = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: Material(
          color: Colors.black54,
          child: SafeArea(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '인터넷 연결이 끊겼습니다.\n네트워크 상태를 확인해주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          _removeNoInternetOverlay();
                          if (Platform.isAndroid) {
                            SystemNavigator.pop();
                          } else if (Platform.isIOS) {
                            exit(0);
                          }
                        },
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_noInternetOverlay!);
  }

  void _removeNoInternetOverlay() {
    _noInternetOverlay?.remove();
    _noInternetOverlay = null;
    _isDialogShowing = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'GateON',
            darkTheme: darkTheme,
            theme: lightTheme,
            // OS 다크 모드와 무관하게 항상 라이트 테마로 고정
            themeMode: ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
            ],
            locale: const Locale('ko', 'KR'),
            routerConfig: _router.setRouter,
            builder: (context, child) {
              return ResponsiveWrapper.builder(child,
                  minWidth: 428,
                  defaultScale: true,
                  breakpoints: [
                    const ResponsiveBreakpoint.resize(480, name: MOBILE),
                    const ResponsiveBreakpoint.resize(800, name: TABLET),
                    const ResponsiveBreakpoint.resize(1000, name: DESKTOP),
                  ],
                  // background: Container(color: const Color(0xFFF5F5F5)));
                  background: Container(color: const Color.fromARGB(252, 7, 0, 0)));
            }),
      ),
    );
  }
}

class DesktopWeb extends StatelessWidget {
  DesktopWeb({super.key});

  final _router = AppRouter();

  /// 무작업 자동 로그아웃 처리: 로그인 정보 삭제 + 브라우저 세션 마커 제거 + 로그인 페이지 이동.
  Future<void> _idleLogout() async {
    final secureModel = SecureModel(tokenData: TokenData(), loginStatus: LoginStatus.logout);
    await AppConfig.to.shared.setString('secureInfo', jsonEncode(secureModel.toJson()));
    AppConfig.to.secureModel = secureModel;
    clearBrowserSession();
    logger.d('무작업 ${SessionConfig.autoLogoutDuration.inMinutes}분 경과 - 자동 로그아웃');
    _router.setDesktopRouter.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'GateON',
        darkTheme: lightTheme,
        theme: lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
        ],
        locale: const Locale('ko', 'KR'),
        themeMode: ThemeMode.system,
        routerConfig: _router.setDesktopRouter,
        builder: (context, child) => IdleTimeoutWrapper(
          timeout: SessionConfig.autoLogoutDuration,
          checkInterval: SessionConfig.activityCheckInterval,
          onTimeout: _idleLogout,
          child: ResponsiveWrapper.builder(child,
              defaultScale: true,
              minWidth: 0,
              breakpoints: [
                const ResponsiveBreakpoint.resize(1200, name: DESKTOP, scaleFactor: 1.0),
                const ResponsiveBreakpoint.autoScale(600, name: TABLET, scaleFactor: 0.5),
                const ResponsiveBreakpoint.autoScale(480, name: MOBILE, scaleFactor: 0.4),
                const ResponsiveBreakpoint.autoScale(428, name: MOBILE, scaleFactor: 0.35),
                const ResponsiveBreakpoint.autoScaleDown(240, name: MOBILE, scaleFactor: 0.2),
                const ResponsiveBreakpoint.autoScaleDown(10, name: MOBILE, scaleFactor: 0.1),
              ],
              background: Container(color: const Color(0xFFF5F5F5))),
        ),
      ),
    );
  }
}

class AppConfig {
  static AppConfig get to => AppConfig();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      aOptions: AndroidOptions(
        resetOnError: true,
    encryptedSharedPreferences: true,
  ));
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static FirebasePerformance? get performance => kIsWeb ? null : FirebasePerformance.instance;
  static FirebaseAnalytics? get analytics => kIsWeb ? null : FirebaseAnalytics.instance;
  static late final SharedPreferences _shared;
  static late SecureModel _secureModel;

  FlutterSecureStorage get storage => _storage;

  SharedPreferences get shared => _shared;

  /// 차단 상태(profile_status)는 민감정보가 아니고, 암호화 저장소의 resetOnError 리셋에
  /// 휩쓸려 null이 되면 "다른 MDM" 오탐을 유발한다. → 일반 SharedPreferences로 전환.
  /// 읽을 때 과거 암호화 저장소에 있던 값이 있으면 1회 마이그레이션한다.
  Future<String?> readProfileStatus() async {
    final v = _shared.getString('profile_status');
    if (v != null) return v;
    // 레거시(암호화) 값 → SharedPreferences로 이관. 읽기 실패해도 크래시 없이 null 처리.
    try {
      final legacy = await _storage.read(key: 'profile_status');
      if (legacy != null) {
        await _shared.setString('profile_status', legacy);
      }
      return legacy;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeProfileStatus(String value) async {
    await _shared.setString('profile_status', value);
  }

  SecureModel get secureModel => _secureModel;

  set secureModel(SecureModel secureModel) => {_secureModel = secureModel};

  DeviceInfoPlugin get deviceInfo => _deviceInfoPlugin;

  static String? _deviceId;
  static String? _manufacturer;
  static String? _model;
  static String? _osVersion;
  static String? _appVersion;

  static Future<String?> getDeviceId() async {
    if (_deviceId != null) return _deviceId;
    _deviceId = await _storage.read(key: 'deviceId');
    if (_deviceId == null && Platform.isAndroid) {
      final id = await AndroidMethodChannel.to.getId();
      if (id != null) {
        await _storage.write(key: 'deviceId', value: id);
        _deviceId = id;
      }
    }
    return _deviceId;
  }

  static String? _cachedTimeInstalled;

  static Future<String> getTimeInstalled() async {
    if (_cachedTimeInstalled != null) return _cachedTimeInstalled!;
    String? value;
    if (Platform.isIOS) {
      value = _shared.getString('time_installed');
    } else {
      value = await _storage.read(key: 'time_installed');
      if (value == null || value == 'null') {
        value = _shared.getString('time_installed');
      }
    }
    if (value == null || value == 'null' || int.tryParse(value) == null) {
      value = '${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: 'time_installed', value: value);
      await _shared.setString('time_installed', value);
    }
    _cachedTimeInstalled = value;
    return value;
  }

  String? get manufacturer => _manufacturer;
  String? get model => _model;
  String? get osVersion => _osVersion;
  String? get appVersion => _appVersion;

  static Future init({required VoidCallback callback}) async {
    // await dotenv
    WidgetsFlutterBinding.ensureInitialized();
    setPathUrlStrategy();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _shared = await SharedPreferences.getInstance();

    if (!kIsWeb) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        if (e is! FirebaseException || e.code != 'duplicate-app') rethrow;
      }
      if(Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        _manufacturer = info.manufacturer;
        _model = info.model;
        _osVersion = 'Android ${info.version.release}';
        await getTimeInstalled();
      }

      if(Platform.isIOS){
        final info = await _deviceInfoPlugin.iosInfo;
        _manufacturer = 'Apple';
        _model = info.utsname.machine;
        _osVersion = '${info.systemName} ${info.systemVersion}';

        await getTimeInstalled();
      }
      final appInfo = await PackageInfo.fromPlatform();
      _appVersion = appInfo.version;

    }
    // 외부 config.json(웹) 에서 세션/자동로그아웃 정책 로드. 실패 시 기본값 유지.
    await SessionConfig.load();

    final secureString = _shared.getString('secureInfo');
    if (secureString == null) {
      _secureModel = SecureModel(tokenData: TokenData(), loginStatus: LoginStatus.logout, role: Role.ROLE_ENTERPRISE);
    } else {
      final secureData = SecureModel.fromJson(jsonDecode(secureString));
      // [웹 재접속 자동로그인 방지]
      // 로그인 정보는 남아있지만(localStorage) 브라우저 세션 마커가 없으면(sessionStorage)
      // = 브라우저/탭을 닫았다가 다시 접속한 상황 → 자동로그인 방지를 위해 로그아웃 처리.
      // (새로고침 F5 는 같은 세션이라 마커가 유지되므로 로그인 유지됨)
      if (kIsWeb && SessionConfig.requireLoginOnReopen && secureData.loginStatus == LoginStatus.login && !hasBrowserSession()) {
        secureData.loginStatus = LoginStatus.logout;
        secureData.tokenData = TokenData();
        await _shared.setString('secureInfo', jsonEncode(secureData.toJson()));
        logger.d('웹 재접속 감지 - 자동로그인 방지(로그아웃 처리)');
      }
      _secureModel = secureData;
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await _shared.setString('app_version', packageInfo.version);

    callback();
  }
}
