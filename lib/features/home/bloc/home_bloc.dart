import 'dart:async';
import 'dart:io';


import 'package:GateON/core/core.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import "package:convert/convert.dart" show hex;
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart';
import '../repository/home_repository.dart';

part 'generated/home_bloc.g.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<CommonEvent, HomeState> with StreamTransform, WidgetsBindingObserver {
  HomeBloc(this._ticker) : super(const HomeState()) {
    WidgetsBinding.instance.addObserver(this);
    on<Initial>(_onInitial);
    on<GetEnterPrise>(_onGetEnterPrise);
    on<SetTicker>(_onSetTicker);
    on<DisableDevice>(_onDisableDevice);
    on<EnableDevice>(_onEnableDevice);
    on<ScanQR>(_onScanQR);
    on<TagNFC>(_onTagNFC);
    on<Location>(_onLocation);
    on<Manual>(_onManual);
    on<Cancel>(_onCancel);
    on<Code>(_onCode);
    on<_TimerTicked>(_onTicked, transformer: droppable());
    on<ScanBeacon>(_onScanBeacon);
    // on<ScanBeacon>(_onScanBeacon, transformer: throttleDroppable());
    on<BeaconDetected>(_onBeaconDetected, transformer: throttleDroppable());
    on<BeaconMatched>(_onBeaconMatched);
    on<ActionControl>(_onActionControl);
    on<Delete>(_onDelete);
    on<Ban>(_onBan);
    on<NeedCameraPermission>(_onNeedCameraPermission);
    on<Error>(_onError);
    on<Init>(_onInit);
    on<ChangeInstallStatus>(_onChangeInstallStatus);
    on<CheckOtherMdm>(_onCheckOtherMdm);
    on<DismissOtherMdmDialog>(_onDismissOtherMdmDialog);
    on<ShowBleList>(_onShowBleList);
  }

  final Ticker _ticker;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const int _duration = 0;

  StreamSubscription<int>? _tickerSubscription;
  StreamSubscription<List<ScanResult>>? _beaconSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  /// 비콘 "못 찾음" 판정 타이머. 스캔을 다시 시작할 때 이전 타이머를 반드시 취소해야
  /// 이전 스캔의 타이머가 새 스캔 도중에 터져 즉시 "감지된 BLE 없음"이 뜨는 것을 막는다.
  Timer? _beaconTimeoutTimer;

  /// 스캔 중 감지된 전체 BLE 결과(등록 비콘을 못 찾았을 때 다이얼로그로 보여주기 위함)
  List<ScanResult> _lastScanResults = [];


  /// 우리 비콘 serviceData의 고정 프리픽스(앞 5바이트). 모든 우리 비콘 공통이며, tag는 이 5바이트 뒤부터다.
  /// (실측: serviceData = 64 27 11 4C B9 + [비콘별 tag]. tag 예: C3000013849F, C300001384A0)
  /// 주변의 다른 BLE 기기를 우리 비콘으로 오인하지 않도록 이 프리픽스로 우리 비콘만 식별한다.
  static const List<int> _beaconPrefix = [0x64, 0x27, 0x11, 0x4C, 0xB9];

  /// 우리 비콘이 광고하는 서비스 UUID(스캔 필터용). 실측 serviceUuids=[fda5].
  static final Guid _beaconServiceUuid = Guid('fda5');

  /// serviceData가 우리 비콘 프리픽스로 시작하는지(=우리 비콘인지) 검사.
  static bool _hasBeaconPrefix(List<int> data) {
    if (data.length < _beaconPrefix.length) return false;
    for (int i = 0; i < _beaconPrefix.length; i++) {
      if (data[i] != _beaconPrefix[i]) return false;
    }
    return true;
  }

  /// ScanResult의 serviceData 중 우리 비콘 프리픽스를 가진 항목이 하나라도 있는지.
  static bool _isOurBeacon(ScanResult r) {
    for (final v in r.advertisementData.serviceData.values) {
      if (_hasBeaconPrefix(v)) return true;
    }
    return false;
  }


  /// 비콘 단일 연속 스캔 시간(초). 이 시간 동안 못 찾으면 감지된 BLE 목록을 표시한다.
  static const int _scanSeconds = 8;

  /// 최근 스캔 시작 시각들(스루틀 선제 방지용). Android는 30초에 스캔 5회 초과 시 막힌다.
  final List<DateTime> _recentScanStarts = [];
  StreamSubscription? _QrSubscription;

  /// iOS: 직전 틱의 isMobileConfigInstalled 값 (메모리 전용 — 앱 재시작 시 null로 초기화됨).
  /// 프로파일 삭제를 "정적 상태(false)"가 아니라 "true→false 전이(삭제 순간)"로만 감지해
  /// 재시작 잔재로 인한 오발동을 막기 위해 사용한다.
  bool? _prevMobileConfigInstalled;

  /// iOS: 직전 틱의 cameraRestricted 값 (메모리 전용).
  /// 차단 프로파일 삭제는 "카메라가 막혔다가 풀린 전이"로 판정한다.
  /// (해제 프로파일을 다운로드만 해도 인증서가 남아 result가 true로 유지될 수 있어,
  ///  result 전이로는 차단 프로파일 삭제를 놓칠 수 있기 때문)
  bool? _prevCameraRestricted;

  /// iOS: 직전 틱의 isOtherMdm 값 (메모리 전용).
  /// 직전 틱이 다른 MDM 차단 상태였으면 카메라가 풀린 것은 "다른 MDM 해제"이지
  /// GateON 차단 프로파일 삭제가 아니므로, 차단 프로파일 삭제 감지에서 제외하기 위함.
  bool? _prevIsOtherMdm;

  /// 비콘 한 사이클(사용자가 비콘으로 차단 또는 해제를 시작~완료)에서 액션이 이미 1번 발생했는지.
  /// 비콘 스캔은 5초(firstScan) → 10초 2단계로 돌아가며 상시 구독(_beaconSubscription)이 각 스캔마다
  /// 같은 비콘을 다시 잡아 ActionControl이 중복 발생 → 차단/해제완료가 2번 기록되는 문제가 있다.
  /// 매칭돼 액션이 나가면 true로 두고 이후 스캔/매칭을 무시하며, 사용자가 새 비콘 동작을 시작할 때 false로 리셋한다.
  bool _beaconActionDispatched = false;

  /// 비콘 한 사이클에서 프로파일 조회(POST /url)가 이미 나갔는지.
  /// _onBeaconDetected는 감지된 비콘마다·throttle 재진입마다 getProfileWithDevice를 호출하는데,
  /// 서버는 POST /url마다 차단/해제 완료를 기록하므로 조회가 중복되면 완료가 여러 번 찍힌다.
  /// 조회를 1번으로 고정하기 위한 플래그(액션 가드 _beaconActionDispatched와 분리). 조회 실패 시 재시도 위해 false로 되돌린다.
  bool _beaconFetchDispatched = false;

  /// 이번 비콘 사이클의 버튼 의도('DISABLE'=차단, 'ENABLE'=해제).
  /// 감지된 비콘 타입(tagType)이 이 의도와 다르면 반대 동작을 실행하지 않는다.
  String? _beaconIntent;

  /// 앱이 포그라운드로 복귀하면 1초 틱을 기다리지 않고 즉시 카메라/다른 MDM 상태를 재평가한다.
  /// (다른 MDM 프로파일을 설치하고 돌아왔을 때 차단화면이 잠깐 보이는 깜빡임 방지)
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      add(const _TimerTicked(duration: 0));
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerSubscription?.cancel();
    _beaconSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _beaconTimeoutTimer?.cancel();
    // 홈 화면 종료(예: Ban으로 /ban 이동) 시 진행 중인 전역 비콘 스캔을 확실히 중단한다.
    // (중단하지 않으면 스캔이 살아남아 메인 복귀 후 새 구독이 이를 잡아 /url을 재조회 → 등록되지 않은 태그 오류)
    FlutterBluePlus.stopScan();
    return super.close();
  }

  /// 기능 초기화
  _onInit(Init event, Emitter<HomeState> emit) async {
    emit(state.copyWith(enterPrise: Enterprise().copyWith(enterpriseFunction: EnterpriseFunction(
        locationEnable: true, manualDisable: true,manualEnable: true,qrDisable: true,nfcDisable: true,nfcEnable: true,beaconDisable: true,beaconEnable: true))));

  }

  /// 초기화
  _onInitial(Initial event, Emitter<HomeState> emit) async {
    try{
    /// set initial value
    var cameraPermissionStatus = await Permission.camera.status;

    // 카메라 상태 즉시 반영하여 흰 화면 방지
    // 단, iOS에서 다른 MDM이 막은 경우(GateON 차단 의도 없는데 카메라 restricted)엔
    // 붉은 차단화면이 잠깐 깜빡이지 않도록 granted로 내보낸다.
    final bool iosOtherMdmAtStart = Platform.isIOS && await _isIosOtherMdmBlocking();
    emit(state.copyWith(
      cameraPermissionStatus: iosOtherMdmAtStart ? PermissionStatus.granted : cameraPermissionStatus,
      status: iosOtherMdmAtStart ? CommonStatus.otherMdm : null,
    ));

    // storage 읽기 실패(최초 설치 시 Keystore 미초기화 등)해도 null로 처리하고 계속 진행
    String installedTime;
    String installedTime2;
    String blockedTime;
    String acceptedTime;
    String code;

      await AppConfig.to.storage.write(key: 'guide_status', value: 'true');
      installedTime = await AppConfig.getTimeInstalled();
      // installedTime2 = AppConfig.to.shared.getString('time_installed')?? '2';
      blockedTime = _safeTimeValue(await AppConfig.to.storage.read(key: 'time_blocked'));
      acceptedTime = _safeTimeValue(await AppConfig.to.storage.read(key: 'time_accepted'));
      code = await AppConfig.to.storage.read(key: 'code') ?? 'null';

    final platform =  MethodChannel('mguard/android');
    // TODO: Implement deep linking when app_links is properly configured
    final appLinks = AppLinks();
    final initialLink = await appLinks.getInitialAppLink();
    if(initialLink!= null){
      final uri = initialLink;
      logger.d('설치');
      logger.d(uri);
      logger.d(uri.host);
      logger.d(uri.path);
      if(uri.host == 'flutter' && uri.path == '/specificFunction'){
        logger.d('차단실행');

        add(ScanQR(tagId:uri.queryParameters['id']));
      }else{
        logger.d('호스트 또는 경로가 일치하지 않습니다.');
      }
    }else{
      _QrSubscription = appLinks.allUriLinkStream.listen((link) {
        if(link != null){
          final uri = link;
          if (uri.host == 'flutter' && uri.path == '/specificFunction') {

            add(ScanQR(tagId:uri.queryParameters['id']));
          }else{
            add(Error(errorMessage: '등록된 QR이 없거나 qr코드가 일치하지 않습니다.'));
          }
        }
      },onError: (e){
        add(Error(errorMessage: e.toString()));
      });
    }


    /// code가 있으면 기업 정보를 가져온다.
    if (code != 'null') {
      add(GetEnterPrise(code: code));
    }
    /// 안드로이드 디바이스 어드민 상태체크
    if (Platform.isAndroid) {
      cameraPermissionStatus = await _checkAndroidAdminStatus();
      logger.d('카메라 권한 ${cameraPermissionStatus}');
      // platform.setMethodCallHandler((call) async {
      //   logger.d(call.toString());
      //   if (call.method == "uninstall_canceled") {
      //     logger.d("삭제방지");
      //     emit(state.copyWith(isUninstall: false));
      //   }
      //   if (call.method == "update"){
      //     logger.d("관리자 활성화 성공");
      //     emit(state.copyWith(isUninstall: false));
      //   }
      //
      // });

             platform.setMethodCallHandler((call) async {
                   if (call.method == "native_error") {
                     final message = call.arguments as String?;
                     emit(state.copyWith(status: CommonStatus.error, errorMessage: message ?? '알 수 없는 오류가 발생했습니다.'));
                   } else {
                     logger.d("삭제방지 ${state.isUninstall}");
                     add(ChangeInstallStatus(isUninstall: false));
                   }
                 });

    }


    /// 상태 저장 (Android: otherMdm 체크 후 동시 emit)
    if(Platform.isAndroid){
      CommonStatus? initialStatus;
      // restricted인 경우 otherMdm 체크
      bool otherMdmShown = false;
      if (cameraPermissionStatus == PermissionStatus.restricted) {
        String? tpassStatus;
        bool readFailed = false;
        try {
          tpassStatus = await AppConfig.to.readProfileStatus();
        } catch (e) {
          // 읽기 에러 = 우리 상태 '모름' → 다른 MDM 추측 금지, 사용자에게 안내 다이얼로그
          readFailed = true;
          logger.e('profile_status 읽기 실패: $e');
        }
        if (readFailed) {
          initialStatus = CommonStatus.storageError;
        } else if (tpassStatus != 'disable') {
          // 다른 MDM이 차단 중
          initialStatus = CommonStatus.otherMdm;
          otherMdmShown = true;
        }
      }
      emit(state.copyWith(
        installedTime: installedTime,
        // 다른 MDM 감지 시 차단(붉은)화면 대신 해제(정상)화면을 보여준다
        cameraPermissionStatus: initialStatus == CommonStatus.otherMdm ? PermissionStatus.granted : cameraPermissionStatus,
        blockedTime: blockedTime,
        acceptedTime: acceptedTime,
        status: initialStatus,
        otherMdmDialogShown: otherMdmShown,
      ));
    }else if(Platform.isIOS){
      // 앱 재시작 시 전이 판정용 _prev* 값이 null이라 "재시작 직후 프로파일 삭제"를 놓치는 것을 막기 위해,
      // 현재 네이티브 상태(카메라 차단/프로파일 설치)로 이전값을 초기화한다.
      // (다운로드만 한 상태는 카메라가 안 막혀 있어 false로 초기화 → 삭제해도 전이 없음 → 오발동 없음)
      try {
        final initPlatform = const MethodChannel('mguard/ios/mobileconfig');
        // 프로파일 상태 확인: 앱 내장 인증서 파일 결함 등 "앱 자체 오류"면 사용자에게 안내한다.
        // (installed/not_installed 는 정상, error 만 앱 결함 → 관리자 문의 안내)
        try {
          final Map<dynamic, dynamic> ps = await initPlatform.invokeMethod('getProfileStatus');
          if (ps['status'] == 'error') {
            logger.e('프로파일 인증서 확인 오류: ${ps['reason']}');
            add(const Error(errorMessage: '앱 인증 정보를 확인할 수 없습니다.\n관리자에게 문의해주세요.'));
          }
        } catch (e) {
          logger.e('getProfileStatus 호출 실패: $e');
        }
        final Map<dynamic, dynamic> initBlockInfo = await initPlatform.invokeMethod('getCameraBlockSource');
        final bool initCameraRestricted = initBlockInfo['cameraRestricted'] as bool? ?? false;
        final bool initResult = initBlockInfo['gateOnProfileInstalled'] as bool? ?? false;
        _prevCameraRestricted = initCameraRestricted;
        _prevMobileConfigInstalled = initResult;
        _prevIsOtherMdm = await _isIosOtherMdmBlocking();

        // 앱이 꺼진 동안 프로파일이 삭제된 경우는 전이(틱)로 못 잡으므로, 재시작 시 1회 정적 비교로 감지한다.
        // 카메라가 안 막혀있는데(initCameraRestricted=false) 차단/해제 기록이 남아있으면 = 꺼진 사이 프로파일 삭제됨.
        if (!initCameraRestricted) {
          final installedNow = await AppConfig.to.storage.read(key: 'profileInstalled');
          final psNow = await AppConfig.to.readProfileStatus();
          final unlockNow = await AppConfig.to.storage.read(key: 'unlockInstalled');
          if (installedNow == 'true' && psNow == 'disable') {
            // 차단완료 기록 있는데 카메라 안 막힘 = 차단 프로파일이 삭제됨
            // (차단 프로파일이 그대로면 카메라가 막혀 있어 여기 안 들어옴 / 순수 다운로드만이면 installed!='true')
            logger.d('차단 프로파일 삭제 감지 (재시작 정적 비교)');
            HomeRepository.to.registerAbnormal(await AppConfig.to.storage.read(key: 'code'));
            add(const Ban(error: '3'));
          } else if (unlockNow == 'true' && !initResult && psNow == 'enable' && installedNow == 'false') {
            // 해제완료 거친 해제 프로파일이 삭제됨 (인증서 사라짐)
            logger.d('해제 프로파일 삭제 감지 (재시작 정적 비교)');
            await AppConfig.to.storage.write(key: 'unlockInstalled', value: 'false');
            HomeRepository.to.registerAbnormal(await AppConfig.to.storage.read(key: 'code'));
            add(const Ban(error: '3'));
          }
        }
      } catch (e) {
        logger.d('iOS 초기 상태 읽기 실패: $e');
      }

      HomeRepository.to.getProfileInstalled(await AppConfig.getDeviceId() ?? "").then((value) async {
        logger.d("서버에서 상태값 : ${value}");
        if (value == true) {
          // 현재 차단 중인 경우에만 'true' 반영 — 새 차단 시작 후 _onActionControl의 'false' 초기화를 덮어쓰지 않기 위함
          final profileStatus = await AppConfig.to.readProfileStatus();
          if (profileStatus == 'disable') {
            AppConfig.to.storage.write(key: 'profileInstalled', value: 'true');
          }
        } else {
          AppConfig.to.storage.write(key: 'profileInstalled', value: 'false');
        }
      });

      // iOS: otherMdm 체크 후 동시 emit
      CommonStatus? initialStatus;
      bool otherMdmShown = false;
      if (await _isIosOtherMdmBlocking()) {
        initialStatus = CommonStatus.otherMdm;
        otherMdmShown = true;
      }

      emit(state.copyWith(
        installedTime: installedTime,
        // 다른 MDM 감지 시 차단(붉은)화면 대신 해제(정상)화면을 보여준다
        cameraPermissionStatus: initialStatus == CommonStatus.otherMdm ? PermissionStatus.granted : cameraPermissionStatus,
        blockedTime: blockedTime,
        acceptedTime: acceptedTime,
        status: initialStatus,
        otherMdmDialogShown: otherMdmShown,
      ));
    }
    /// Ticker 시작
      add(SetTicker(permissionStatus: cameraPermissionStatus));
       }catch(e){
      add(Error(errorMessage: e.toString()));
       }

  }

  /// 기업 정보 가져오기
  _onGetEnterPrise(GetEnterPrise event, Emitter<HomeState> emit) async {
    await HomeRepository.to
        .checkCode(event.code)
        .then(
          (value) => emit(state.copyWith(enterPrise: value.data)),
        )
        .catchError(
          (error) async {
            add(Error(errorMessage: '${error} '
                ''
                // '업체정보 에러, 코드값 : ${event.code}'
                ''));
            // await AppConfig.to.storage.delete(key: 'code');
          },
        );
  }

  /// Ticker 시작 && 비콘 Subscription 설정
  _onSetTicker(SetTicker event, Emitter<HomeState> emit) {
    try{
      _tickerSubscription?.cancel();
      _tickerSubscription = _ticker.stopwatch(duration: 1).listen((duration) => add(_TimerTicked(duration: duration)));
      logger.d('티커');
      if (!event.permissionStatus.isRestricted && !event.permissionStatus.isGranted) {
        add(const Ban(error: '1'));
      }
      // Initial이 재실행될 때마다 리스너가 쌓이지 않도록 이전 구독 해제 후 등록
      _beaconSubscription?.cancel();
      _beaconSubscription = FlutterBluePlus.scanResults.listen((results) async {
        // 활성 스캔 중이 아닐 때는 무시한다. flutter_blue_plus는 재구독 시 마지막 스캔 결과를
        // 다시 방출하는데, 메인 복귀로 새 구독이 생기면 이전 MBeacon이 재방출돼 /url을 재조회하는 문제 방지.
        // [진단] 스캔 결과 원본 로그: 이름 / serviceData 유무 / MBeacon 매칭 여부
        final _diag = results.map((r) {
          final n = r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : r.device.advName;
          // serviceData의 UUID key까지 찍는다 → iOS withServices 필터에 넣을 서비스 UUID 확인용
          final svcKeys = r.advertisementData.serviceData.keys.map((k) => k.str).toList();
          return '"$n"(svc:$svcKeys,mb:${n.contains('MBeacon')})';
        }).toList();
        logger.d('[스캔결과] scanning=${FlutterBluePlus.isScanningNow} 개수=${results.length} $_diag');
        _lastScanResults = results; // 다이얼로그용 전체 BLE 목록은 가드와 무관하게 항상 수집
        if (!FlutterBluePlus.isScanningNow) return;
        for (ScanResult r in results) {
          // 우리 비콘 고정 프리픽스(64 27 11 4C B9)로 시작하는 serviceData를 가진 기기만 우리 비콘으로 본다.
          // 이름(MBeacon)은 iOS에서 scan-response로 늦게/누락되기 쉬워 조건에서 뺀다.
          // 프리픽스는 우리 비콘만의 확실한 식별자라 단독으로 정확하고, iOS 이름-패킷 의존도 없어 견고하다.
          if (_isOurBeacon(r)) {
            _beaconTimeoutTimer?.cancel(); // 감지됐으니 "못 찾음" 판정 타이머 취소
            await FlutterBluePlus.stopScan();
            add(BeaconDetected({'MBeacon': r}));
            return;
          }
        }
      }, onError: (e) {
        // 스캔 스트림 오류(스루틀 등) 백업 감지(A) → 사용자 안내. (선제 카운트 B가 놓친 경우 대비)
        // [진단] 어떤 스트림 오류인지 타입/코드/설명을 모두 찍는다.
        final detail = e is FlutterBluePlusException
            ? 'FBP code=${e.code} func=${e.function} desc=${e.description}'
            : '${e.runtimeType}: $e';
        logger.e('[스캔스트림오류] $detail');
        final isThrottle = e is FlutterBluePlusException &&
            (e.code == 6 || (e.description?.toLowerCase().contains('frequent') ?? false));
        add(Error(errorMessage: isThrottle
            ? '너무 자주 시도했습니다.\n약 30초 후 다시 시도해주세요.'
            : '스캔 중 오류가 발생했습니다.\n다시 시도해주세요.\n[$detail]'));
      });
    }catch (e){
      emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
    }

  }

  /// 디바이스 비활성화
  _onDisableDevice(DisableDevice event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: CommonStatus.loading));
    switch (event.interactionType) {
      // /// qr
      // case InteractionType.qr:
      //   add(ScanQR(enabled: false));
      /// nfc
      case InteractionType.nfc:
        NfcAvailability availability = await NfcManager.instance.checkAvailability();
        logger.d(availability);
        if (availability != NfcAvailability.enabled) {
          emit(state.copyWith(status: CommonStatus.dialog, ));
          return;
        }else{
          final nfc = NfcManager.instance;
          nfc.startSession(onDiscovered: (NfcTag tag) async {
            if (Platform.isAndroid) {
              Navigator.of(navigatorKey.currentContext!).pop();
            }
            add(TagNFC(tag: tag, enabled: false));
            nfc.stopSession();
          }, onSessionErrorIos: (error) async {
            if (Platform.isAndroid) {
              Navigator.of(navigatorKey.currentContext!).pop();
            }
            add(const Cancel());
            nfc.stopSession();
          }, pollingOptions: {NfcPollingOption.iso14443,NfcPollingOption.iso15693,NfcPollingOption.iso18092});
          return;
        }

      /// manual
      case InteractionType.manual:
        add(Manual(enabled: false, code: event.code));

      /// beacon
      case InteractionType.beacon:
        _beaconActionDispatched = false; // 새 비콘 사이클 시작 → 중복 방지 플래그 리셋
        _beaconFetchDispatched = false;  // 조회 중복 방지 플래그도 리셋
        _beaconIntent = 'DISABLE';       // 버튼 의도: 차단
        add(ScanBeacon(state.firstScan));
        break;
      default:
        break;
    }
  }

  /// 디바이스 활성화
  _onEnableDevice(EnableDevice event, Emitter<HomeState> emit) {
    emit(state.copyWith(status: CommonStatus.loading));
    switch (event.interactionType) {
      /// nfc
      case InteractionType.nfc:
        final nfc = NfcManager.instance;
        nfc.startSession(
            onDiscovered: (NfcTag tag) async {
          if (Platform.isAndroid) {
            Navigator.of(navigatorKey.currentContext!).pop();
          }
          add(TagNFC(tag: tag, enabled: true));
          nfc.stopSession();
        }, onSessionErrorIos: (error) async {
          if (Platform.isAndroid) {
            Navigator.of(navigatorKey.currentContext!).pop();
          }
          add(const Cancel());
          nfc.stopSession();
        },
            pollingOptions: {NfcPollingOption.iso14443,NfcPollingOption.iso15693,NfcPollingOption.iso18092});
        return;
    /// beacon
      case InteractionType.beacon:
        _beaconActionDispatched = false; // 새 비콘 사이클 시작 → 중복 방지 플래그 리셋
        _beaconFetchDispatched = false;  // 조회 중복 방지 플래그도 리셋
        _beaconIntent = 'ENABLE';        // 버튼 의도: 해제
        add(ScanBeacon(state.firstScan));
      /// manual
      case InteractionType.manual:
        add(Manual(enabled: true, code: event.code));
      /// location
      case InteractionType.location:
        add(Location());
      default:
        break;
    }
  }
  _onChangeInstallStatus(ChangeInstallStatus event, Emitter<HomeState> emit) async {
    _checkAndroidAdminStatus().then((value){
      emit(state.copyWith(isUninstall: event.isUninstall));
    });
   //
  }                                         
  /// 취소
  _onCancel(Cancel event, Emitter<HomeState> emit) async {
    // await FlutterBluePlus.stopScan();
    // emit(state.copyWith(status: CommonStatus.initial));
  }

  /// 수동 차단/허용
  _onManual(Manual event, Emitter<HomeState> emit) async {
    // 차단 시에만 다른 MDM 체크 (해제 시에는 체크 안함)
    if (!event.enabled) {
      if (Platform.isAndroid) {
        final cameraStatus = await _checkAndroidAdminStatus();
        final tpassStatus = await AppConfig.to.readProfileStatus();

        // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
        if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
          return;
        }
      } else if (Platform.isIOS) {
        if (await _isIosOtherMdmBlocking()) {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
          return;
        }
      }
    }

    emit(state.copyWith(status: CommonStatus.initial));
    logger.d(event.enabled);
    await HomeRepository.to.getProfileWithManual(event.code ?? '', event.enabled).then((data) async {
      logger.d(data?.url);
      await AppConfig.to.storage.write(key: 'code', value: data?.enterprise?.code);
      if(event.enabled){
        add(ActionControl(enabled: event.enabled, isActive: data?.isActive ?? true, profileUrl: data?.url, enterprise: data?.enterprise, tagType:"ENABLE"));
      }else{
        add(ActionControl(enabled: event.enabled, isActive: data?.isActive ?? true, profileUrl: data?.url, enterprise: data?.enterprise,tagType:"DISABLE"));
      }

    }).catchError((e) async {
      final isConnected = await ConnectivityService.to.checkConnection();
      if (!isConnected) {
        emit(state.copyWith(status: CommonStatus.error, errorMessage: '인터넷 연결을 확인해주세요.'));
      } else {
        emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
      }
    });
  }

  _onCode(Code event, Emitter<HomeState> emit) async {
    await HomeRepository.to
        .checkCode(event.code)
        .then(
          (value) async {
            await AppConfig.to.storage.write(key: 'code', value: '${event.code}');
            emit(state.copyWith(status: CommonStatus.initial));
            add(Location());
          }
    )
        .catchError(
          (error) async {
          emit(state.copyWith(status: CommonStatus.error, errorMessage: error));
        await AppConfig.to.storage.delete(key: 'code');
      },
    );
  }

  /// 위치기반 해제
  _onLocation(Location event, Emitter<HomeState> emit) async {
    final code = await AppConfig.to.storage.read(key: 'code');
    if (await Permission.location.status != PermissionStatus.granted) {
      Permission.location.request();
    } else {
      if(code == '' || code == null){
        emit(state.copyWith(status: CommonStatus.code));
      }else{
        await HomeRepository.to.getProfileWithLocation(code).then((value) async {
          if (Platform.isAndroid) {
            final deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
            if (!deviceManage) {
              await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
                await AndroidMethodChannel.to.enableCamera().then((value) {
                  if (!value) {
                    emit(state.copyWith(status: CommonStatus.success));
                  } else {
                    // 우리 차단은 풀었는데도 카메라가 여전히 막혀있음 = 다른 MDM이 차단 중
                    emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
                  }
                });
              });
            } else {
              await AndroidMethodChannel.to.enableCamera().then((value) {
                if (!value) {
                  emit(state.copyWith(status: CommonStatus.success));
                } else {
                  // 우리 차단은 풀었는데도 카메라가 여전히 막혀있음 = 다른 MDM이 차단 중
                  emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
                }
              });
            }
          } else {
            emit(state.copyWith(status: CommonStatus.success, profileUrl: value?.url));
          }

          await AppConfig.to.writeProfileStatus('enable');
        }).catchError((error) async {
          final isConnected = await ConnectivityService.to.checkConnection();
          if (!isConnected) {
            add(const Error(errorMessage: '인터넷 연결을 확인해주세요.'));
          } else {
            String errorMessage = error.toString();
            add(Error(errorMessage: errorMessage));
          }
        });
      }
    }
  }

  /// QR 차단
  _onScanQR(ScanQR event, Emitter<HomeState> emit) async {
    // 다른 MDM 체크 (차단 진행 전)
    if (Platform.isAndroid) {
      final cameraStatus = await _checkAndroidAdminStatus();
      final tpassStatus = await AppConfig.to.readProfileStatus();

      // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
      if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
        return;
      }
    } else if (Platform.isIOS) {
      if (await _isIosOtherMdmBlocking()) {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
        return;
      }
    }

    emit(state.copyWith(status: CommonStatus.initial));
    String? tagId;
    if(event.barcode == null && event.tagId != null){
      tagId = event.tagId;
    }else if (event.tagId == null && event.barcode != null){
      final rawValue = event.barcode!.barcodes.first.rawValue;
      tagId = rawValue != null ? Uri.parse(rawValue).queryParameters['id'] : null;
    }
    logger.d('qr태그${tagId ?? '없음'}');
    await HomeRepository.to.getProfileWithDevice(tagId ?? '').then((data) async {
      logger.d(data?.toJson());
      add(ActionControl(enabled: false, isActive: data?.isActive ?? true, profileUrl: data?.url, enterprise: data?.enterprise, tagType: data?.tagType));


      await AppConfig.to.storage.write(key: 'code', value: data?.enterprise?.code);
      await AppConfig.to.writeProfileStatus('wait');

    }).catchError((error) async {
      logger.d(error);
      final isConnected = await ConnectivityService.to.checkConnection();
      if (!isConnected) {
        add(const Error(errorMessage: '인터넷 연결을 확인해주세요.'));
      } else {
        String errorMessage = error.toString();
        add(Error(errorMessage: errorMessage));
      }
    });
  }

  /// NFC 태그
  _onTagNFC(TagNFC event, Emitter<HomeState> emit) async {
    // 다른 MDM 체크 (차단 진행 전)
    if (Platform.isAndroid) {
      final cameraStatus = await _checkAndroidAdminStatus();
      final tpassStatus = await AppConfig.to.readProfileStatus();

      // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
      if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
        return;
      }
    } else if (Platform.isIOS) {
      if (await _isIosOtherMdmBlocking()) {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
        return;
      }
    }

    var nfcIdCode = '';
    if (Platform.isAndroid) {
      /// 안드로이드 NDEF 규격 NFC 사용
      Ndef? ndef = Ndef.from(event.tag);
      NdefAndroid? ndefAndroid = NdefAndroid.from(event.tag);
      nfcIdCode = hex.encode(ndefAndroid!.tag.id.toList()) ;
    } else {
      /// iOS MiFare 규격 NFC 사용
      MiFareIos? miFare = MiFareIos.from(event.tag);
      nfcIdCode = hex.encode(miFare?.identifier ?? []).toUpperCase();
    }
    await HomeRepository.to.getProfileWithDevice(nfcIdCode).then((data) async {
      logger.d(data?.toJson());
      add(ActionControl(enabled: event.enabled, isActive: data?.isActive ?? true, profileUrl: data?.url, enterprise: data?.enterprise, tag: event.tag, tagType: data?.tagType));


      await AppConfig.to.storage.write(key: 'code', value: data?.enterprise?.code);
      await AppConfig.to.writeProfileStatus('wait');

    }).catchError((error) async {
      logger.d(error);
      final isConnected = await ConnectivityService.to.checkConnection();
      if (!isConnected) {
        add(const Error(errorMessage: '인터넷 연결을 확인해주세요.'));
      } else {
        add(const Error(errorMessage: '차단 NFC을 찾을 수 없습니다.\n다시 시도해주세요.'));
      }
    });
    emit(state.copyWith(status: CommonStatus.initial));
  }

  /// 비콘 스캔
  _onScanBeacon(ScanBeacon event, Emitter<HomeState> emit) async {
    // 이미 이번 사이클에서 비콘이 매칭되어 액션이 나갔으면 중복 스캔을 돌리지 않는다.
    if (_beaconActionDispatched) return;
    // Android는 위치 서비스(GPS)가 꺼져 있으면 BLE 스캔 결과가 아예 안 나온다.
    // (권한과 별개로 '위치 서비스 ON'이 필요) → 꺼져 있으면 안내하고 스캔을 건너뛴다.
    if (Platform.isAndroid && !await Geolocator.isLocationServiceEnabled()) {
      add(const Error(errorMessage: '위치 서비스가 꺼져 있어\n비콘을 검색할 수 없습니다.\n위치(GPS)를 켜고 다시 시도해주세요.'));
      return;
    }
    // 짧은 시간에 스캔이 반복되면(30초 5회 이상) 플랫폼별로 다르게 대응한다.
    // - Android: OS가 30초 5회 초과를 실제로 막으므로(SCAN_FAILED_SCANNING_TOO_FREQUENTLY),
    //   그 전에 안내하고 스캔을 건너뛴다. (3초 텀으론 안 풀림)
    // - iOS: 하드 제한은 없고, 반복 스캔이 쌓이면 "기기별 중복 억제(dedup)"로 우리 비콘만 잠깐 빠진다.
    //   BLE 스택이 잠깐 idle이면 그 억제 기억이 풀리므로, 안내 없이 짧은 텀만 주고 이어서 스캔한다.
    final _now = DateTime.now();
    _recentScanStarts.removeWhere((t) => _now.difference(t) > const Duration(seconds: 30));
    if (_recentScanStarts.length >= 5) {
      if (Platform.isAndroid) {
        // 다시 가능해지는 시점 = "가장 오래된 시도 + 30초". 그때까지 실제 남은 초를 계산해 안내한다.
        final oldest = _recentScanStarts.first;
        final remainSec = 30 - _now.difference(oldest).inSeconds;
        final n = remainSec < 1 ? 1 : remainSec; // 최소 1초로 표기
        add(Error(errorMessage: '너무 자주 시도했습니다.\n약 $n초 후 다시 시도해주세요.'));
        return;
      }
      // iOS: dedup 억제 창이 풀릴 만큼만 idle 후 카운터 리셋하고 진행 (사용자는 조금 더 걸린다고만 느낌)
      await Future.delayed(const Duration(seconds: 3));
      _recentScanStarts.clear();
    }
    _recentScanStarts.add(DateTime.now());
    emit(state.copyWith(firstScan: false, scanResult: {}));
    logger.d('스캔시작');
    await _adapterStateSubscription?.cancel();

    // 어댑터가 확정 상태(on/off)가 될 때까지 기다린다.
    // (iOS의 CBCentralManager는 앱 시작 직후 .unknown → .poweredOn으로 비동기 전환되는데,
    //  .first로 첫 값을 잡으면 그 .unknown을 받아 "블루투스 확인" 오탐이 발생 → 첫 시도만 실패하고
    //  두 번째엔 on으로 잡히던 문제. firstWhere로 on/off 확정값을 기다려 해결)
    BluetoothAdapterState adapterState;
    try {
      adapterState = await FlutterBluePlus.adapterState
          .firstWhere((s) => s == BluetoothAdapterState.on || s == BluetoothAdapterState.off)
          .timeout(const Duration(seconds: 4), onTimeout: () => FlutterBluePlus.adapterStateNow);
    } catch (_) {
      adapterState = FlutterBluePlus.adapterStateNow;
    }

    if (adapterState == BluetoothAdapterState.on) {
      _startBeaconScan();
    } else {
      add(const Error(errorMessage: '블루투스 상태를 확인해주세요.'));
    }
  }

  /// 단일 연속 스캔 실행. 비콘이 잡히면 _beaconSubscription에서 즉시 stopScan하고,
  /// _scanSeconds초 내 못 잡으면 감지된 BLE 목록을 표시한다. (끊었다 켜는 2단계/재시도 없음 → 빈틈 없음)
  void _startBeaconScan() async {
    // 스캔 상태가 꼬여(이전 스캔이 완전히 안 끝난 채) 새 startScan이 즉시 완료돼 실제로 스캔이
    // 안 도는 문제가 있었다(whenComplete가 14ms만에 호출). → 시작 전에 이전 스캔을 확실히 멈추고
    // 잠깐 정리 시간을 준 뒤 새로 시작한다. 그리고 판정은 startScan의 Future(whenComplete)에
    // 의존하지 않고, "스캔 시작 후 고정 _scanSeconds초" 타이머로 한다. (Future 즉시 완료와 무관)
    // 이전 스캔의 판정 타이머가 남아있으면 취소한다. (안 하면 이전 타이머가 새 스캔 도중 터져
    //  "8초 경과"라며 즉시 목록이 뜨는 문제 발생 — 실제로는 이전 스캔 기준 8초)
    _beaconTimeoutTimer?.cancel();
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    await Future.delayed(const Duration(milliseconds: 300)); // BLE 스택 정리 여유

    try {
      // continuousUpdates: false → iOS는 adv/scan-response를 병합해 이름+serviceData를 함께 준다.
      // withServices(fda5)로 주변 무관 기기 필터, lowLatency로 촘촘히 스캔.
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: _scanSeconds),
        continuousUpdates: false,
        withServices: [_beaconServiceUuid],
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (error) {
      final detail = error is FlutterBluePlusException
          ? 'FBP code=${error.code} func=${error.function} desc=${error.description}'
          : '${error.runtimeType}: $error';
      logger.e('[스캔시작실패] $detail');
      add(Error(errorMessage: '차단 비콘을 찾을 수 없습니다.\n다시 시도해주세요.'));
      return;
    }

    // 판정 타이머: 스캔 시작 후 _scanSeconds(8초) 동안 비콘이 안 잡히면 그때 "감지된 BLE 목록" 표시.
    // (startScan Future가 언제 끝나든 무관하게, 스캔이 도는 전체 시간을 온전히 기다린다)
    _beaconTimeoutTimer = Timer(const Duration(seconds: _scanSeconds), () async {
      if (state.scanResult.isEmpty && !_beaconFetchDispatched && !_beaconActionDispatched) {
        logger.d('비콘 미발견 → 목록 표시 (${_scanSeconds}s 경과)');
        if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
        add(const ShowBleList());
      }
    });
  }

  /// 비콘 감지
  _onBeaconDetected(BeaconDetected event, Emitter<HomeState> emit) async {
    emit(state.copyWith(scanResult: event.result));
    if (state.scanResult.isEmpty) {
      add(const Error(errorMessage: '차단 비콘을 찾을 수 없습니다.\n다시 시도해주세요.3'));
    }
    var beaconMatched = false;
    logger.d('비콘감지');
    state.scanResult.forEach((key, value) async {
      // 이번 사이클에서 이미 프로파일 조회(POST /url)가 나갔으면 중복 호출 방지.
      // (감지된 비콘 다수 + throttle 재진입으로 POST /url이 여러 번 나가 완료기록이 중복되던 문제)
      if (_beaconFetchDispatched) return;
      _beaconFetchDispatched = true; // 조회 확정 → 이 사이클의 추가 조회 차단
      logger.d(key);
      logger.d(value);
      final dataList = value.advertisementData.serviceData.entries.map((e) {
        // 원본 serviceData를 훼손하지 않도록 복사 후 자른다.
        // (원본을 직접 자르면 같은 ScanResult가 _lastScanResults에도 있어 목록 표시 시 이중으로 잘려버림)
        final bytes = List<int>.from(e.value);
        if (bytes.length > 4) {
          bytes.removeRange(0, 5);
        }
        return hex.encode(bytes).toUpperCase();
      }).toList();
      await HomeRepository.to.getProfileWithDevice(dataList.first, action: _beaconIntent).then((data) async {
        logger.d(data?.toJson());

        if (!(data?.isActive ?? true)) {
          add(Ban(error: '2'));
          return;
        }
        add(BeaconMatched(data));
        beaconMatched = true;
        return;
      }).catchError((error) async {
        // /url 조회 실패(예: 등록되지 않은 태그) → 비콘 사이클 종료.
        // (종료하지 않으면 2단계 스캔이 계속 돌며 무효 태그로 /url을 재조회해 스캔이 멈추지 않는다)
        _beaconActionDispatched = true; // 후속 스캔/매칭/조회 차단
        await _adapterStateSubscription?.cancel();
        await FlutterBluePlus.stopScan();
        logger.d('에러 : ${error.toString()}');
        if (beaconMatched) return;
        // 비콘은 감지됐지만 조회 실패(예: 등록되지 않은 태그) → 감지된 BLE 목록(감지된 MBeacon 포함)과 사유를 함께 표시
        logger.d('[목록표시경로] 서버조회실패(886) → ShowBleList');
        add(ShowBleList(reason: '${error}'));
      });
    });
    // emit(state.copyWith(status: CommonStatus.initial));
  }

  /// 비콘 매칭
  _onBeaconMatched(BeaconMatched event, Emitter<HomeState> emit) async {
    // 이번 사이클에서 이미 매칭돼 액션이 나갔으면 중복 매칭 무시 (2단계 스캔으로 인한 중복 방지)
    if (_beaconActionDispatched) return;
    // 버튼 의도(차단/해제)와 감지된 비콘 타입이 다르면 반대 동작을 실행하지 않는다.
    // (예: 차단을 눌렀는데 해제 비콘만 감지된 경우 → 해제 로직이 도는 것을 방지)
    final detectedType = event.data?.tagType == 'ENABLE' ? 'ENABLE' : 'DISABLE';
    if (_beaconIntent != null && detectedType != _beaconIntent) {
      _beaconActionDispatched = true;
      await _adapterStateSubscription?.cancel();
      await FlutterBluePlus.stopScan();
      add(Error(errorMessage: _beaconIntent == 'DISABLE'
          ? '차단 비콘이 아닙니다.\n차단 비콘을 확인해주세요.'
          : '해제 비콘이 아닙니다.\n해제 비콘을 확인해주세요.'));
      return;
    }
    // 차단 시에만 다른 MDM 체크 (해제 시에는 체크 안함)
    final isDisableAction = event.data?.tagType != 'ENABLE';
    if (isDisableAction) {
      if (Platform.isAndroid) {
        final cameraStatus = await _checkAndroidAdminStatus();
        final tpassStatus = await AppConfig.to.readProfileStatus();

        // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
        if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
          return;
        }
      } else if (Platform.isIOS) {
        if (await _isIosOtherMdmBlocking()) {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
          return;
        }
      }
    }

    // 액션 확정 → 이 사이클의 후속 스캔/중복 매칭을 차단하고, 진행 중인 스캔을 즉시 종료한다.
    _beaconActionDispatched = true;
    await _adapterStateSubscription?.cancel();
    await FlutterBluePlus.stopScan();

    await AppConfig.to.storage.write(key: 'code', value: event.data?.enterprise?.code);
    await AppConfig.to.writeProfileStatus('wait');
    emit(state.copyWith(status: CommonStatus.initial));
    if(Platform.isAndroid){
      add(ActionControl(enabled: event.data?.tagType == 'ENABLE' ? true : false, isActive: event.data?.isActive ?? true, profileUrl: event.data?.url, enterprise: event.data?.enterprise, tagType: event.data?.tagType));
    }else{
      add(ActionControl(enabled: event.data?.tagType == 'ENABLE' ? true : false, isActive: event.data?.isActive ?? true, profileUrl: event.data?.url, enterprise: event.data?.enterprise));
    }
  }

  /// Ticker
  /// [CAUTION]
  /// Do not edit this function
  ///
  /// [NOTE]
  /// Author: 엄기영
  /// Date: 2023.12.28
  ///
  /// 메인 카메라 기능 작동 체크 로직이므로, 수정시 주의해주세요.
  /// 카메라 이외 기능 추가 시, 해당 로직에서 권한을 추가해서 체크하는 로직으로 구성해주세요.
  ///
  _onTicked(_TimerTicked event, Emitter<HomeState> emit) async {
    /// 차단 시점
    final blockTime = await AppConfig.to.storage.read(key: 'time_blocked') ?? '';
      // logger.d("${state.isUninstall} 활성화여부");
    /// 카메라 권한 상태 체크
    await Permission.camera.status.then((cameraPermissionStatus) async {
      /// 안드로이드 디바이스 어드민 상태체크 + 카메라 체크
      bool isOtherMdmHandled = false;  // 다른 MDM 처리 여부 플래그
      bool iosEnableHandled = false;   // iOS 해제완료(C_ENABLE)를 이 틱에서 이미 전송했는지 여부 (중복 전송 방지)
      if (Platform.isAndroid && state.isUninstall == false) {
        cameraPermissionStatus = await _checkAndroidAdminStatus();
        logger.d('카메라 상태 체크 : ${cameraPermissionStatus}');

        /// 카메라 차단 출처 확인 (TPASS vs 다른 MDM)
        final tpassStatus = await AppConfig.to.readProfileStatus();

        if (cameraPermissionStatus == PermissionStatus.restricted) {
          // TPASS가 차단 중인지 확인
          final tpassIsBlocking = tpassStatus == 'wait' || tpassStatus == 'disable';
          if (!tpassIsBlocking) {
            // 다른 MDM이 차단 중 - status를 otherMdm으로 변경 (다이얼로그는 표시 안함)
            if (state.status != CommonStatus.otherMdm) {
              emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted));
            }
            isOtherMdmHandled = true;
          }
        } else if (cameraPermissionStatus == PermissionStatus.granted && state.cameraPermissionStatus.isRestricted) {
          // 이전: restricted → 현재: granted (해제됨)
          // 다른 MDM 상태였으면 다른 MDM이 해제한 것
          if (state.status == CommonStatus.otherMdm) {
            isOtherMdmHandled = true;  // 다른 MDM이 해제함, 알림음 스킵
          }
        }
      }
      // iOS에서 Mobile Config 설치 여부 확인
      if (Platform.isIOS) {
        final platform = MethodChannel('mguard/ios/mobileconfig');
        final bool result = await platform.invokeMethod('isMobileConfigInstalled');
        final String? installed = await AppConfig.to.storage.read(key: 'profileInstalled');

        /// iOS 카메라 차단 출처 확인 (TPASS vs 다른 MDM)
        final Map<dynamic, dynamic> blockInfo = await platform.invokeMethod('getCameraBlockSource');
        final bool cameraRestricted = blockInfo['cameraRestricted'] as bool? ?? false;
        final String? profileStatus = await AppConfig.to.readProfileStatus();
        // GateON이 실제 차단 중 = 프로파일 설치됨(result) && (차단 의도(profile_status) 또는 차단완료 기록(installed))
        // 카메라가 막혔는데 그게 아니면 다른 MDM.
        // installed=='true'는 GateON이 차단완료를 보낸 기록이므로 GateON 차단이 확실함
        // (해제 시도로 profile_status='enable'이 됐지만 해제 프로필 미구성으로 차단이 유지되는 모순 상태를 다른 MDM으로 오판하지 않기 위함)
        final bool gateOnBlocking = result && (profileStatus == 'disable' || profileStatus == 'wait' || installed == 'true');
        final bool isOtherMdm = cameraRestricted && !gateOnBlocking;

        if (isOtherMdm) {
          // 다른 MDM이 차단 중 - status를 otherMdm으로 변경 (다이얼로그는 표시 안함)
          if (state.status != CommonStatus.otherMdm) {
            emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted));
          }
          isOtherMdmHandled = true;
        } else if (state.cameraPermissionStatus.isRestricted && !cameraPermissionStatus.isRestricted) {
          // 이전: restricted → 현재: granted (해제됨)
          // 다른 MDM 상태였으면 다른 MDM이 해제한 것
          if (state.status == CommonStatus.otherMdm) {
            isOtherMdmHandled = true;  // 다른 MDM이 해제함, 알림음 스킵
          }
        }

        // 프로파일 설치/제거 감지 — 차단/해제 프로파일이 같은 인증서를 공유해 isMobileConfigInstalled로는
        // 구분할 수 없으므로(둘 다 설치 시 true), 실제 카메라 차단 상태(cameraRestricted)를 기준으로 판단한다.
        if (!isOtherMdm) {
          if (cameraRestricted && installed != 'true' && profileStatus == 'disable') {
            // 차단완료: 차단 프로파일로 카메라가 막힘
            logger.d('차단완료 API 전송 (cameraRestricted 기반)');
            // 프로파일 구성이 확인됨 → 남아있는 인앱 사파리 뷰를 닫고 홈 화면으로 복귀
            closeInAppWebView();
            HomeRepository.to.updateProfileInstalled(
              await AppConfig.getDeviceId() ?? "", true, "C_DISABLE"
            ).catchError((e) { logger.e('차단완료 API 전송 실패: $e'); });
            await AppConfig.to.storage.write(key: "profileInstalled", value: 'true');
            await AppConfig.to.storage.write(key: "unlockInstalled", value: 'false');
          } else if (!cameraRestricted && installed == 'true') {
            if (profileStatus == 'enable' && result) {
              // 해제완료: 해제 프로파일이 설치되어(result=true) 차단을 풀어 카메라가 정상화됨 → 서버 전송 + 해제 사운드
              logger.d('해제완료 API 전송 (cameraRestricted 기반)');
              // 프로파일 구성이 확인됨 → 남아있는 인앱 사파리 뷰를 닫고 홈 화면으로 복귀
              closeInAppWebView();
              HomeRepository.to.updateProfileInstalled(
                await AppConfig.getDeviceId() ?? "", true, "C_ENABLE"
              ).catchError((e) { logger.e('해제완료 API 전송 실패: $e'); });
              iosEnableHandled = true;  // 아래 카메라 권한 전이 경로에서 중복 전송/알림음 방지
              await AppConfig.to.storage.write(key: "profileInstalled", value: 'false');
              await AppConfig.to.storage.write(key: "unlockInstalled", value: 'true');
              // 해제 알림음 재생 (무음 모드에서도 재생)
              try {
                await _audioPlayer.setAudioContext(
                  AudioContext(
                    iOS: AudioContextIOS(
                      category: AVAudioSessionCategory.playback,
                      options: {AVAudioSessionOptions.mixWithOthers},
                    ),
                    android: AudioContextAndroid(
                      isSpeakerphoneOn: true,
                      stayAwake: false,
                      contentType: AndroidContentType.sonification,
                      usageType: AndroidUsageType.alarm,
                      audioFocus: AndroidAudioFocus.gain,
                    ),
                  ),
                );
                await _audioPlayer.setVolume(1.0);
                await _audioPlayer.play(AssetSource('sounds/enable.mp3'));
                logger.d('해제완료 알림음 재생');
              } catch (e) {
                logger.e('해제 알림음 재생 실패: $e');
              }
            } else if (_prevCameraRestricted == true && _prevIsOtherMdm != true) {
              // 이상감지: 차단 중인데 카메라가 풀림 = 차단 프로파일이 삭제된 것.
              // 카메라가 막혀있다가(직전 틱 restricted=true) 풀린 "전이(삭제 순간)"일 때만 감지한다.
              // 단, 직전 틱이 다른 MDM 차단(_prevIsOtherMdm)이었으면 카메라 풀림은 "다른 MDM 해제"이므로 제외한다.
              // (result가 아닌 cameraRestricted 전이로 판정 — 해제 프로파일 다운로드로 result가 true로 남아도
              //  차단 프로파일 삭제를 놓치지 않기 위함. 다운로드만 하고 재시작한 경우는 직전 restricted가 null이라 안 잡힘)
              logger.d('차단 프로파일 삭제 감지');
              HomeRepository.to.registerAbnormal(await AppConfig.to.storage.read(key: 'code'));
              add(const Ban(error: '3'));
            }
          } else if (!cameraRestricted && !result && installed == 'false' && profileStatus == 'enable') {
            // 해제 상태에서 해제 프로파일이 삭제됨
            // "정적 상태(result=false)"가 아니라 직전 틱 true→현재 false "전이(삭제 순간)"일 때만 감지한다.
            // (앱 재시작 시 _prevMobileConfigInstalled가 null이라 전이로 안 잡혀 잔재 오발동 방지)
            final unlockInstalled = await AppConfig.to.storage.read(key: 'unlockInstalled');
            if (_prevMobileConfigInstalled == true && unlockInstalled == 'true') {
              logger.d('해제 프로파일 삭제 감지');
              await AppConfig.to.storage.write(key: "unlockInstalled", value: 'false');
              HomeRepository.to.registerAbnormal(await AppConfig.to.storage.read(key: 'code'));
              add(const Ban(error: '3'));
            }
          }
        }
        // 다음 틱 전이 판정을 위해 현재 상태 기억
        _prevMobileConfigInstalled = result;
        _prevCameraRestricted = cameraRestricted;
        _prevIsOtherMdm = isOtherMdm;
      }


      /// 카메라 권한 상태가 변경되었을시 (다른 MDM 처리 중이면 스킵)
      if (cameraPermissionStatus != state.cameraPermissionStatus && !isOtherMdmHandled) {
        switch (cameraPermissionStatus) {
          case PermissionStatus.granted:
            await AppConfig.to.readProfileStatus().then((value) async {
              switch (value) {
                case 'enable':
                  // cameraRestricted 기반 경로(위)에서 이미 해제완료를 전송했으면 중복 전송/알림음 방지를 위해 스킵
                  if (iosEnableHandled) break;
                  if (Platform.isIOS) {
                    try {
                      await HomeRepository.to.updateProfileInstalled(await AppConfig.getDeviceId() ?? "", true, "C_ENABLE");
                    } catch (e) {
                      emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
                    }
                    await AppConfig.to.storage.write(key: "profileInstalled", value: 'false');
                  }
                  /// 카메라 해제 시 알림음 재생 (무음 모드에서도 재생)
                  await _audioPlayer.setAudioContext(
                    AudioContext(
                      iOS: AudioContextIOS(
                        category: AVAudioSessionCategory.playback,
                        options: {
                          AVAudioSessionOptions.mixWithOthers,
                        },
                      ),
                      android: AudioContextAndroid(
                        isSpeakerphoneOn: true,
                        stayAwake: false,
                        contentType: AndroidContentType.sonification,
                        usageType: AndroidUsageType.alarm,
                        audioFocus: AndroidAudioFocus.gain,
                      ),
                    ),
                  );
                  await _audioPlayer.setVolume(1.0);
                  await _audioPlayer.play(AssetSource('sounds/enable.mp3'));
                  logger.d('카메라 해제 알림음 재생');
                  break;
                case 'wait':
                  if (Platform.isIOS) {
                    try {
                      await HomeRepository.to.updateProfileInstalled(await AppConfig.getDeviceId() ?? "", true, "C_ENABLE");
                    } catch (e) {
                      emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
                    }
                    await AppConfig.to.storage.write(key: "profileInstalled", value: 'false');
                  }
                  /// 정상적으로 카메라 차단을 해제함
                  await AppConfig.to.writeProfileStatus('enable');
                  AppConfig.to.storage.write(key: 'time_accepted', value: '${DateTime.now().millisecondsSinceEpoch}');
                  emit(state.copyWith(acceptedTime: '${DateTime.now().millisecondsSinceEpoch}'));
                  break;
                case 'disable':
                  /// 카메라 차단을 해제하고 다시 차단함 (비정상 이용)
                  add(const Ban(error: '9'));
                  break;
                default:
                  break;
              }
            });
            break;
          case PermissionStatus.restricted:
            // iOS: 카메라가 막혔지만 GateON이 실제 차단 중(프로파일 설치 && 차단 의도)이 아니면
            // → 다른 MDM이 막은 것. GateON 차단 처리(profile_status='disable', C_DISABLE)를 하지 않고 otherMdm으로 둔다
            //   (이 처리를 안 막으면 profile_status가 'disable'로 덮어써져 다른 MDM을 영영 못 잡는 악순환 발생)
            if (Platform.isIOS) {
              final platform = MethodChannel('mguard/ios/mobileconfig');
              final bool gateOnInstalled = await platform.invokeMethod('isMobileConfigInstalled');
              final ps = await AppConfig.to.readProfileStatus();
              final bool gateOnBlocking = gateOnInstalled && (ps == 'disable' || ps == 'wait');
              if (!gateOnBlocking) {
                if (state.status != CommonStatus.otherMdm) {
                  emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
                }
                break;
              }
            }
            // iOS에서 Mobile Config 설치 여부 확인
            if (Platform.isIOS) {
              final platform = MethodChannel('mguard/ios/mobileconfig');
              final bool result = await platform.invokeMethod('isMobileConfigInstalled');
              final String? alreadySent = await AppConfig.to.storage.read(key: 'profileInstalled');
              if (result && alreadySent != 'true'){
                /// 서버로 uuid 전송
                HomeRepository.to.updateProfileInstalled(await AppConfig.getDeviceId() ?? "", true, "C_DISABLE").catchError((e){
                  emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
                });
                await AppConfig.to.storage.write(key: "profileInstalled", value: 'true');
              }
            }
            /// 카메라를 차단함
            await AppConfig.to.writeProfileStatus('disable');
            AppConfig.to.storage.write(key: 'time_blocked', value: '${DateTime.now().millisecondsSinceEpoch}');
            emit(state.copyWith(blockedTime: '${DateTime.now().millisecondsSinceEpoch}'));

            /// 카메라 차단 시 알림음 재생 (무음 모드에서도 재생)
            try {
              // 오디오 컨텍스트 설정 (포그라운드에서도 재생되도록)
              await _audioPlayer.setAudioContext(
                AudioContext(
                  iOS: AudioContextIOS(
                    category: AVAudioSessionCategory.playback,
                    options: {
                      AVAudioSessionOptions.mixWithOthers,
                    },
                  ),
                  android: AudioContextAndroid(
                    isSpeakerphoneOn: true,
                    stayAwake: false,
                    contentType: AndroidContentType.sonification,
                    usageType: AndroidUsageType.alarm,
                    audioFocus: AndroidAudioFocus.gain,
                  ),
                ),
              );
              await _audioPlayer.setVolume(1.0);
              // if(Platform.isIOS){
              //   await _audioPlayer.play(AssetSource('sounds/install_profile.mp3'));
              // }else{
              //
              // }
              await _audioPlayer.play(AssetSource('sounds/disable.mp3'));
              logger.d('카메라 차단 알림음 재생');
            } catch (e) {
              logger.e('알림음 재생 실패: $e');
            }
            break;
          case PermissionStatus.denied:
          case PermissionStatus.permanentlyDenied:
            // 카메라 권한이 거부된 상태는 "비정상(Ban)"이 아니라 사용자가 권한을 켜야 하는 상황.
            // → 비정상 처리 대신 권한 설정 안내를 띄운다.
            add(const NeedCameraPermission());
            break;
          default:
            // 그 외 예상 못한 권한 상태(limited/provisional 등)만 비정상으로 처리
            add(const Ban(error: '4'));
            break;
        }
        emit(state.copyWith(cameraPermissionStatus: cameraPermissionStatus));
      } else if (cameraPermissionStatus != state.cameraPermissionStatus && isOtherMdmHandled) {
        // 다른 MDM 처리 중이어도 카메라 상태는 업데이트 (알림음만 스킵)
        emit(state.copyWith(cameraPermissionStatus: cameraPermissionStatus));
      }
      if (blockTime.isNotEmpty) {
        final date = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(int.parse(blockTime)));
        emit(state.copyWith(timeAgo: date.toString().split('.')[0]));
      }
      emit(state.copyWith(duration: _duration + event.duration));
    }).catchError((error) {
      emit(state.copyWith(status: CommonStatus.error));
      return error;
    });
  }

  /// 안드로이드 앱 삭제 기능
  _onDelete(Delete event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isUninstall: true));
    await AndroidMethodChannel.to.requestUninstall();
    // .then((val) async {
    //   await AndroidMethodChannel.to.checkDeviceAdminStatus().then((value){
    //     logger.d("관리자 해제 후 $value");
    //     // if(value == false){
    //     //   emit(state.copyWith(isUninstall: false));
    //     // }
    //   });
    // });
    // await AndroidMethodChannel.to.checkDeviceAdminStatus().then((value) async {
    //   if (value) {
    //   } else {
    //     print(value);
    //     await AndroidMethodChannel.to.uninstallApp();
    //   }
    //   // await AndroidMethodChannel.to.uninstallApp();
    // });

  }

  /// 비정상 이용자 BAN
  /// 등록 비콘을 못 찾음 → 감지된 전체 BLE 목록을 표시용 문자열로 변환해 다이얼로그로 노출
  _onShowBleList(ShowBleList event, Emitter<HomeState> emit) {
    _beaconActionDispatched = true; // 이 사이클 종료 (추가 스캔/조회 방지)
    final devices = _lastScanResults.map((r) {
      final name = r.advertisementData.advName.isNotEmpty
          ? r.advertisementData.advName
          : (r.device.advName.isNotEmpty ? r.device.advName : '(이름 없음)');
      // 서버로 보내는 tagId(serviceData hex, 앞 5바이트 제외)를 계산해 표시. (_onBeaconDetected와 동일)
      String tagId = '-';
      final entries = r.advertisementData.serviceData.entries;
      if (entries.isNotEmpty) {
        final bytes = List<int>.from(entries.first.value); // 원본 훼손 방지 위해 복사
        if (bytes.length > 4) bytes.removeRange(0, 5);
        if (bytes.isNotEmpty) tagId = hex.encode(bytes).toUpperCase();
      }
      return '$tagId  |  ${r.rssi}dBm  |  $name';
    }).toList();
    emit(state.copyWith(status: CommonStatus.bleList, bleDevices: devices, errorMessage: event.reason ?? '게이트온 비콘을 찾을 수 없습니다.'));
  }

  /// 카메라 권한 거부 → 비정상(Ban) 대신 권한 허용 안내. 화면에서 설정 이동 다이얼로그를 띄운다.
  _onNeedCameraPermission(NeedCameraPermission event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: CommonStatus.needPermission));
  }

  _onBan(Ban event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: CommonStatus.failure, ban: event.error ));
    _tickerSubscription?.cancel();
    // 비정상(Ban) 처리 이후 비콘 스캔이 계속 돌며 무효화된 device로 /url을 재조회해
    // "등록되지 않은 device 태그" 오류가 메인에 뜨는 것을 막는다.
    _beaconActionDispatched = true; // 후속 스캔/매칭 차단
    _beaconFetchDispatched = true;  // 후속 조회 차단
    await _adapterStateSubscription?.cancel();
    await FlutterBluePlus.stopScan();
  }

  /// 카메라 제어
  _onActionControl(ActionControl event, Emitter<HomeState> emit) async {
    try{
      // 차단/해제 시점의 업체 코드 저장 (updateProfileInstalled 전송 시 사용)
      await AppConfig.to.storage.write(key: 'last_action_code', value: event.enterprise?.code);

      if (Platform.isAndroid) {
        if (!event.isActive) {
          add(const Ban(error: '5'));
          return;
        }
        final deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
        // 차단/해제 완료 기록은 POST /url 응답 경로에서 방식과 함께 서버가 생성하므로
        // Android는 updateProfileInstalled(POST /profileinstalled)를 호출하지 않는다 (중복/빈칸 방지)
        if (!deviceManage) {
          await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
            if(event.tagType == "ENABLE") {
              await AppConfig.to.writeProfileStatus('enable');
              await AndroidMethodChannel.to.enableCamera();
            } else {
              await AppConfig.to.writeProfileStatus('disable');
              await AndroidMethodChannel.to.disableCamera();
            }
          });
        } else {
          if(event.tagType == "ENABLE") {
            await AppConfig.to.writeProfileStatus('enable');
            await AndroidMethodChannel.to.enableCamera();
          } else {
            await AppConfig.to.writeProfileStatus('disable');
            await AndroidMethodChannel.to.disableCamera();
          }
        }
      }else{

        if(event.tagType == "ENABLE" || event.enabled == true) {
          await AppConfig.to.writeProfileStatus('enable');
          // 카메라가 이미 granted 상태면 _onTicked 상태변화 감지 불가 → C_ENABLE 직접 호출.
          // 단, 차단완료 기록(profileInstalled=='true')이 있을 때만 1번 전송하고 플래그를 내린다.
          // (비콘은 감지가 반복 발생해 ActionControl(ENABLE)이 여러 번 들어오므로, 가드가 없으면
          //  카메라 granted 상태에서 해제완료가 매번 재전송되어 중복 기록됨. 또한 _onTicked의
          //  cameraRestricted 기반 해제완료 경로와도 상호배타로 만들어 중복을 막는다.)
          final cameraStatus = await Permission.camera.status;
          final installed = await AppConfig.to.storage.read(key: 'profileInstalled');
          if (cameraStatus.isGranted && installed == 'true') {
            await HomeRepository.to.updateProfileInstalled(
              await AppConfig.getDeviceId() ?? "", true, "C_ENABLE"
            ).catchError((e) { logger.e('해제완료 API 전송 실패: $e'); });
            await AppConfig.to.storage.write(key: 'profileInstalled', value: 'false');
            await AppConfig.to.storage.write(key: 'unlockInstalled', value: 'true');
          }
        } else {
          await AppConfig.to.writeProfileStatus('disable');
          await AppConfig.to.storage.write(key: 'profileInstalled', value: 'false');
        }
      }
      emit(state.copyWith(status: CommonStatus.success, profileUrl: event.profileUrl, enterPrise: event.enterprise, tag: event.tag));
    }catch (e){
      emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
    }
  }

  /// iOS: 다른 MDM이 카메라를 차단 중인지 판단
  /// "GateON이 실제로 차단 중"이려면 GateON 프로파일이 설치되어 있고(gateOnProfileInstalled)
  /// 동시에 차단 의도(profile_status == disable/wait)가 있어야 한다.
  /// 카메라가 막혔는데 그게 아니면 다른 MDM이 막은 것으로 판단한다.
  /// (profile_status만 보면 이전 차단 잔재로 'disable'이 남아 다른 MDM을 GateON으로 오판할 수 있어,
  ///  GateON 프로파일 설치 여부를 함께 확인한다.)
  Future<bool> _isIosOtherMdmBlocking() async {
    final platform = const MethodChannel('mguard/ios/mobileconfig');
    try {
      final Map<dynamic, dynamic> blockInfo = await platform.invokeMethod('getCameraBlockSource');
      final bool cameraRestricted = blockInfo['cameraRestricted'] as bool? ?? false;
      if (!cameraRestricted) return false;
      final bool gateOnProfileInstalled = blockInfo['gateOnProfileInstalled'] as bool? ?? false;
      final tpassStatus = await AppConfig.to.readProfileStatus();
      final installed = await AppConfig.to.storage.read(key: 'profileInstalled');
      // installed=='true'(차단완료 기록)도 GateON 차단으로 인정 — 해제 시도로 profile_status='enable'이지만
      // 해제 프로필 미구성으로 차단이 유지되는 모순 상태를 다른 MDM으로 오판하지 않기 위함
      final bool gateOnBlocking = gateOnProfileInstalled && (tpassStatus == 'disable' || tpassStatus == 'wait' || installed == 'true');
      return !gateOnBlocking;
    } catch (e) {
      logger.d('iOS otherMdm 체크 에러: $e');
      return false;
    }
  }

  /// 안드로이드 디바이스 어드민 상태체크
  Future<PermissionStatus> _checkAndroidAdminStatus() async {
    return await AndroidMethodChannel.to.checkDeviceAdminStatus().then((deviceManage) async {
      logger.d(deviceManage);
      if (deviceManage) {
        final camera = await AndroidMethodChannel.to.checkCameraStatus();
        return camera ? PermissionStatus.restricted : PermissionStatus.granted;
      } else {
        await AndroidMethodChannel.to.forceDeviceAdmin();
        return PermissionStatus.granted;
      }
    });
  }

  /// 에러
  _onError(Error event, Emitter<HomeState> emit) {
    emit(state.copyWith(status: CommonStatus.error, errorMessage: event.errorMessage));
    emit(state.copyWith(status: CommonStatus.initial));
  }

  /// 기능 차단 버튼 클릭 시 다른 MDM 체크
  _onCheckOtherMdm(CheckOtherMdm event, Emitter<HomeState> emit) async {
    // 먼저 상태를 initial로 변경하여 listener가 다시 호출될 수 있도록 함
    // emit(state.copyWith(status: CommonStatus.initial));

    if (Platform.isAndroid) {
      final cameraStatus = await _checkAndroidAdminStatus();
      final tpassStatus = await AppConfig.to.readProfileStatus();

      // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
      if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
        return;
      }
    } else if (Platform.isIOS) {
      if (await _isIosOtherMdmBlocking()) {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.granted, otherMdmDialogShown: true));
        return;
      }
    }

    // 다른 MDM이 감지되지 않으면 showBlockModal 상태로 변경
    emit(state.copyWith(status: CommonStatus.showBlockModal));
    // 모달이 표시된 후 상태를 리셋하여 다음 클릭 시 다시 열리도록 함
    emit(state.copyWith(status: CommonStatus.initial));
  }

  /// 다른 MDM 다이얼로그 닫기
  /// status는 otherMdm으로 유지하여 UI에서 다른 MDM 차단 상태를 표시할 수 있도록 함
  _onDismissOtherMdmDialog(DismissOtherMdmDialog event, Emitter<HomeState> emit) {
    emit(state.copyWith(otherMdmDialogShown: false));
  }
}

// storage.read()가 "null" 문자열을 반환하거나 정수가 아닌 값을 반환할 때 빈 문자열로 정규화
String _safeTimeValue(String? value) {
  if (value == null || value == 'null') return '';
  if (int.tryParse(value) == null) return '';
  return value;
}
