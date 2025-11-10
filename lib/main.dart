import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' show Platform;

import 'package:TPASS/core/core.dart';
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

Future<void> main() async {
  logger.d('앱 진입점');
  AppConfig.init(
    callback: () async {
      if (kIsWeb) {
        logger.d('웹');
        runApp(DesktopWeb());
        return;
      }

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      if (Platform.isAndroid) {
        // String? id = await FirebaseInstallations.id;
        await AppConfig.to.storage.read(key: 'deviceId').then((value) async {
          if (value == null) {
            String id = await AndroidMethodChannel.to.getId();
            await AppConfig.to.storage.write(key: "deviceId", value: id);
          }
        });

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

class App extends StatelessWidget {
  App({super.key});

  final _router = AppRouter();

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
            title: 'TPASS',
            darkTheme: darkTheme,
            theme: lightTheme,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'TPASS',
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
        builder: (context, child) => ResponsiveWrapper.builder(child,
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
  static final FirebasePerformance performance = FirebasePerformance.instance;
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static late final SharedPreferences _shared;
  static late SecureModel _secureModel;

  FlutterSecureStorage get storage => _storage;

  SharedPreferences get shared => _shared;

  SecureModel get secureModel => _secureModel;

  set secureModel(SecureModel secureModel) => {_secureModel = secureModel};

  DeviceInfoPlugin get deviceInfo => _deviceInfoPlugin;

  static String? _manufacturer;
  static String? _model;
  static String? _osVersion;
  static String? _appVersion;

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
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if(Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        _manufacturer = info.manufacturer;
        _model = info.model;
        _osVersion = 'Android ${info.version.release}';
        if ((await _storage.read(key: 'time_installed')) == null) {
          _storage.write(key: 'time_installed', value: '${DateTime
              .now()
              .millisecondsSinceEpoch}');
        }
      }

      if(Platform.isIOS){
        final info = await _deviceInfoPlugin.iosInfo;
        _manufacturer = 'Apple';
        _model = info.utsname.machine;
        _osVersion = '${info.systemName} ${info.systemVersion}';

        if(_shared.getString('time_installed') == null){
          _shared.setString( 'time_installed', '${DateTime
              .now()
              .millisecondsSinceEpoch}');
        }
      }
      final appInfo = await PackageInfo.fromPlatform();
      _appVersion = appInfo.version;

    }
    if ((await _storage.read(key: 'time_installed')) == null) {
      _storage.write(key: 'time_installed', value: '${DateTime.now().millisecondsSinceEpoch}');
    }
    final secureString = _shared.getString('secureInfo');
    if (secureString == null) {
      _secureModel = SecureModel(tokenData: TokenData(), loginStatus: LoginStatus.logout, role: Role.ROLE_ENTERPRISE);
    } else {
      final secureData = SecureModel.fromJson(jsonDecode(secureString));
      _secureModel = secureData;
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await _shared.setString('app_version', packageInfo.version);

    callback();
  }
}
