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
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app_links/app_links.dart';
import '../../../main.dart';
import '../repository/home_repository.dart';

part 'generated/home_bloc.g.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<CommonEvent, HomeState> with StreamTransform {
  HomeBloc(this._ticker) : super(const HomeState()) {
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
    on<Error>(_onError);
    on<Init>(_onInit);
    on<ChangeInstallStatus>(_onChangeInstallStatus);
    on<CheckOtherMdm>(_onCheckOtherMdm);
    on<DismissOtherMdmDialog>(_onDismissOtherMdmDialog);
  }

  final Ticker _ticker;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const int _duration = 0;

  StreamSubscription<int>? _tickerSubscription;
  StreamSubscription<List<ScanResult>>? _beaconSubscription;
  StreamSubscription? _QrSubscription;

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
    emit(state.copyWith(cameraPermissionStatus: cameraPermissionStatus));

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
        try {
          tpassStatus = await AppConfig.to.storage.read(key: 'profile_status');
        } catch (e) {
          add(Error(errorMessage: 'Storage read profile_status failed: $e'));
        }
        if (tpassStatus != 'disable') {
          // 다른 MDM이 차단 중
          initialStatus = CommonStatus.otherMdm;
          otherMdmShown = true;
        }
      }
      emit(state.copyWith(
        installedTime: installedTime,
        cameraPermissionStatus: cameraPermissionStatus,
        blockedTime: blockedTime,
        acceptedTime: acceptedTime,
        status: initialStatus,
        otherMdmDialogShown: otherMdmShown,
      ));
    }else if(Platform.isIOS){
      HomeRepository.to.getProfileInstalled(await AppConfig.getDeviceId() ?? "").then((value){
        logger.d("서버에서 상태값 : ${value}");
        AppConfig.to.storage.write(key : "profileInstalled", value: "${value}" );
      });

      // iOS: otherMdm 체크 후 동시 emit
      CommonStatus? initialStatus;
      bool otherMdmShown = false;
      final iosChannel = MethodChannel('mguard/ios/mobileconfig');
      try {
        final Map<dynamic, dynamic> blockInfo = await iosChannel.invokeMethod('getCameraBlockSource');
        final String blockSourceStr = blockInfo['blockSource'] ?? 'none';
        if (blockSourceStr == 'otherMdm') {
          initialStatus = CommonStatus.otherMdm;
          otherMdmShown = true;
        }
      } catch (e) {
        add(Error(errorMessage: 'iOS getCameraBlockSource 에러: $e'));
      }

      emit(state.copyWith(
        installedTime: installedTime,
        cameraPermissionStatus: cameraPermissionStatus,
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
            add(Error(errorMessage: '${error} 업체정보 에러, 코드값 : ${event.code}'));
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
      FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.advName.isNotEmpty && r.advertisementData.serviceData.isNotEmpty && r.advertisementData.advName.contains('MBeacon')) {
            await FlutterBluePlus.stopScan();
            add(BeaconDetected({r.advertisementData.advName: r}));
            return;
          }
        }
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
        final tpassStatus = await AppConfig.to.storage.read(key: 'profile_status');

        // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
        if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: cameraStatus, otherMdmDialogShown: true));
          return;
        }
      } else if (Platform.isIOS) {
        final platform = MethodChannel('mguard/ios/mobileconfig');
        try {
          final Map<dynamic, dynamic> blockInfo = await platform.invokeMethod('getCameraBlockSource');
          final String blockSourceStr = blockInfo['blockSource'] ?? 'none';

          if (blockSourceStr == 'otherMdm') {
            emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.restricted, otherMdmDialogShown: true));
            return;
          }
        } catch (e) {
          add(Error(errorMessage: 'iOS getCameraBlockSource 에러: $e'));
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
                    emit(state.copyWith(status: CommonStatus.error, errorMessage: '차단 해제에 오류가 발생했습니다..'));
                  }
                });
              });
            } else {
              await AndroidMethodChannel.to.enableCamera().then((value) {
                if (!value) {
                  emit(state.copyWith(status: CommonStatus.success));
                } else {
                  emit(state.copyWith(status: CommonStatus.error, errorMessage: '차단 해제에 오류가 발생했습니다..'));
                }
              });
            }
          } else {
            emit(state.copyWith(status: CommonStatus.success, profileUrl: value?.url));
          }

          await AppConfig.to.storage.write(key: 'profile_status', value: 'enable');
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
      final tpassStatus = await AppConfig.to.storage.read(key: 'profile_status');

      // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
      if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: cameraStatus, otherMdmDialogShown: true));
        return;
      }
    } else if (Platform.isIOS) {
      final platform = MethodChannel('mguard/ios/mobileconfig');
      try {
        final Map<dynamic, dynamic> blockInfo = await platform.invokeMethod('getCameraBlockSource');
        final String blockSourceStr = blockInfo['blockSource'] ?? 'none';

        if (blockSourceStr == 'otherMdm') {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.restricted, otherMdmDialogShown: true));
          return;
        }
      } catch (e) {
        logger.d('iOS getCameraBlockSource 에러: $e');
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
      /// data에 tagType이 DISABLE: 차단, ENABLE: 허용 태그 ( 안드로이드일때만 tagType이 있음, 안드로이드일때만 체크하면 됨 )
      if(Platform.isAndroid){
        add(ActionControl(enabled: false, isActive: data?.isActive ?? true, profileUrl: data?.url, enterprise: data?.enterprise, tagType: data?.tagType));
      }else{
        add(ActionControl(enabled: false, isActive: data?.isActive ?? true, profileUrl: data?.url, enterprise: data?.enterprise,));
      }


      await AppConfig.to.storage.write(key: 'code', value: data?.enterprise?.code);
      await AppConfig.to.storage.write(key: 'profile_status', value: 'wait');

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
      final tpassStatus = await AppConfig.to.storage.read(key: 'profile_status');

      // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
      if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: cameraStatus, otherMdmDialogShown: true));
        return;
      }
    } else if (Platform.isIOS) {
      final platform = MethodChannel('mguard/ios/mobileconfig');
      try {
        final Map<dynamic, dynamic> blockInfo = await platform.invokeMethod('getCameraBlockSource');
        final String blockSourceStr = blockInfo['blockSource'] ?? 'none';

        if (blockSourceStr == 'otherMdm') {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.restricted, otherMdmDialogShown: true));
          return;
        }
      } catch (e) {
        logger.d('iOS getCameraBlockSource 에러: $e');
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
      /// data에 tagType이 DISABLE: 차단, ENABLE: 허용 태그 ( 안드로이드일때만 tagType이 있음, 안드로이드일때만 체크하면 됨 )
      if(Platform.isAndroid){
        add(ActionControl(enabled: event.enabled, isActive: data?.isActive ?? true, profileUrl: data?.url, enterprise: data?.enterprise, tag: event.tag, tagType: data?.tagType));
      }else{
        add(ActionControl(enabled: event.enabled, isActive: data?.isActive ?? true, profileUrl: data?.url, enterprise: data?.enterprise, tag: event.tag));
      }


      await AppConfig.to.storage.write(key: 'code', value: data?.enterprise?.code);
      await AppConfig.to.storage.write(key: 'profile_status', value: 'wait');

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
    _beaconSubscription?.resume();
    emit(state.copyWith(firstScan: false, scanResult: {}));
    logger.d(state.scanResult);
    logger.d('스캔시작');
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState bleState) async{
      logger.d(bleState);
      if(bleState == BluetoothAdapterState.on){
        await FlutterBluePlus.startScan(timeout: Duration(seconds:
        event.firstScan ? 5 : 10
        )).catchError((error) {
          logger.d(error);
          add(const Error(errorMessage: '차단 비콘을 찾을 수 없습니다.\n다시 시도해주세요.2'));
        }).whenComplete(() async {
          if (event.firstScan) {
            logger.d('첫번째 스캔');
            FlutterBluePlus.stopScan();
            add(const ScanBeacon(false));
          } else {
          Future.delayed(Duration(seconds: 10), () {
            logger.d('10초 끝');
            logger.d(state.scanResult);
            logger.d(state.scanResult.isEmpty);
            if (state.scanResult.isEmpty) {
              add(const Error(errorMessage: '차단 비콘을 찾을 수 없습니다.\n다시 시도해주세요.1'));
            }
          });
          // }
        }});
      }else if (bleState == BluetoothAdapterState.off){
        add(const Error(errorMessage: '블루투스 상태를 확인해주세요.'));
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
      logger.d(key);
      logger.d(value);
      final dataList = value.advertisementData.serviceData.entries.map((e) {
        if (e.value.length > 4) {
          e.value.removeRange(0, 5);
        }
        return hex.encode(e.value).toUpperCase();
      }).toList();
      await HomeRepository.to.getProfileWithDevice(dataList.first).then((data) async {
        logger.d(data?.toJson());

        if (!(data?.isActive ?? true)) {
          add(Ban(error: '2'));
          return;
        }
        add(BeaconMatched(data));
        beaconMatched = true;
        return;
      }).catchError((error) {
        logger.d('에러 : ${error.toString()}');
        Future.delayed(const Duration(seconds: 3), () {
          if (beaconMatched) return;
          add(Error(errorMessage: '${error}'));
        });
      });
    });
    // emit(state.copyWith(status: CommonStatus.initial));
  }

  /// 비콘 매칭
  _onBeaconMatched(BeaconMatched event, Emitter<HomeState> emit) async {
    // 차단 시에만 다른 MDM 체크 (해제 시에는 체크 안함)
    final isDisableAction = event.data?.tagType != 'ENABLE';
    if (isDisableAction) {
      if (Platform.isAndroid) {
        final cameraStatus = await _checkAndroidAdminStatus();
        final tpassStatus = await AppConfig.to.storage.read(key: 'profile_status');

        // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
        if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: cameraStatus, otherMdmDialogShown: true));
          return;
        }
      } else if (Platform.isIOS) {
        final platform = MethodChannel('mguard/ios/mobileconfig');
        try {
          final Map<dynamic, dynamic> blockInfo = await platform.invokeMethod('getCameraBlockSource');
          final String blockSourceStr = blockInfo['blockSource'] ?? 'none';

          if (blockSourceStr == 'otherMdm') {
            emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.restricted, otherMdmDialogShown: true));
            return;
          }
        } catch (e) {
          logger.d('iOS getCameraBlockSource 에러: $e');
        }
      }
    }

    await AppConfig.to.storage.write(key: 'code', value: event.data?.enterprise?.code);
    await AppConfig.to.storage.write(key: 'profile_status', value: 'wait');
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
      if (Platform.isAndroid && state.isUninstall == false) {
        cameraPermissionStatus = await _checkAndroidAdminStatus();
        logger.d('카메라 상태 체크 : ${cameraPermissionStatus}');

        /// 카메라 차단 출처 확인 (TPASS vs 다른 MDM)
        final tpassStatus = await AppConfig.to.storage.read(key: 'profile_status');

        if (cameraPermissionStatus == PermissionStatus.restricted) {
          // TPASS가 차단 중인지 확인
          final tpassIsBlocking = tpassStatus == 'wait' || tpassStatus == 'disable';
          if (!tpassIsBlocking) {
            // 다른 MDM이 차단 중 - status를 otherMdm으로 변경 (다이얼로그는 표시 안함)
            if (state.status != CommonStatus.otherMdm) {
              emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: cameraPermissionStatus));
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
        final String blockSourceStr = blockInfo['blockSource'] ?? 'none';

        if (blockSourceStr == 'otherMdm') {
          // 다른 MDM이 차단 중 - status를 otherMdm으로 변경 (다이얼로그는 표시 안함)
          if (state.status != CommonStatus.otherMdm) {
            emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: cameraPermissionStatus));
          }
          isOtherMdmHandled = true;
        } else if (state.cameraPermissionStatus.isRestricted && !cameraPermissionStatus.isRestricted) {
          // 이전: restricted → 현재: granted (해제됨)
          // 다른 MDM 상태였으면 다른 MDM이 해제한 것
          if (state.status == CommonStatus.otherMdm) {
            isOtherMdmHandled = true;  // 다른 MDM이 해제함, 알림음 스킵
          }
        }

        // TPASS 프로파일이 삭제된 경우 ban
        if (result == false && installed == "true" && blockSourceStr != 'otherMdm') {
          HomeRepository.to.registerAbnormal(await AppConfig.to.storage.read(key: 'code'));
          add(const Ban(error: '3'));
        }
      }


      /// 카메라 권한 상태가 변경되었을시 (다른 MDM 처리 중이면 스킵)
      if (cameraPermissionStatus != state.cameraPermissionStatus && !isOtherMdmHandled) {
        switch (cameraPermissionStatus) {
          case PermissionStatus.granted:
            await AppConfig.to.storage.read(key: 'profile_status').then((value) async {
              switch (value) {
                case 'enable':
                  if (Platform.isIOS) {
                    final platform = MethodChannel('mguard/ios/mobileconfig');
                    final bool result = await platform.invokeMethod('isMobileConfigInstalled');
                    if (result){
                      /// 서버로 uuid 전송
                      try {
                        await HomeRepository.to.updateProfileInstalled(await AppConfig.getDeviceId() ?? "", true, "C_ENABLE");
                      } catch (e) {
                        emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
                      }
                      await AppConfig.to.storage.write(key: "profileInstalled", value: 'true');
                    }
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
                    final platform = MethodChannel('mguard/ios/mobileconfig');
                    final bool result = await platform.invokeMethod('isMobileConfigInstalled');
                    if (result){
                      /// 서버로 uuid 전송
                      try {
                        await HomeRepository.to.updateProfileInstalled(await AppConfig.getDeviceId() ?? "", true, "C_ENABLE");
                      } catch (e) {
                        emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
                      }
                      await AppConfig.to.storage.write(key: "profileInstalled", value: 'true');
                    }
                  }
                  /// 정상적으로 카메라 차단을 해제함
                  await AppConfig.to.storage.write(key: 'profile_status', value: 'enable');
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
            // iOS에서 Mobile Config 설치 여부 확인
            if (Platform.isIOS) {
              final platform = MethodChannel('mguard/ios/mobileconfig');
              final bool result = await platform.invokeMethod('isMobileConfigInstalled');
              if (result){
                /// 서버로 uuid 전송
                HomeRepository.to.updateProfileInstalled(await AppConfig.getDeviceId() ?? "", true, "C_DISABLE").catchError((e){
                  emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
                });
                await AppConfig.to.storage.write(key: "profileInstalled", value: 'true');
              }
            }
            /// 카메라를 차단함
            await AppConfig.to.storage.write(key: 'profile_status', value: 'disable');
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
          default:
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
  _onBan(Ban event, Emitter<HomeState> emit) {
    emit(state.copyWith(status: CommonStatus.failure, ban: event.error ));
    _tickerSubscription?.cancel();
  }

  /// 카메라 제어
  _onActionControl(ActionControl event, Emitter<HomeState> emit) async {
    try{
      if (Platform.isAndroid) {
        if (!event.isActive) {
          add(const Ban(error: '5'));
          return;
        }
        final deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
        if (!deviceManage) {
          await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
            // if (event.enabled) {
            if(event.tagType == "ENABLE") {
              await AppConfig.to.storage.write(key: 'profile_status', value: 'enable');
              await AndroidMethodChannel.to.enableCamera();
            } else {
              await AppConfig.to.storage.write(key: 'profile_status', value: 'disable');
              await AndroidMethodChannel.to.disableCamera();
            }
          });
        } else {
          // if (event.enabled) {
          if(event.tagType == "ENABLE") {
            await AppConfig.to.storage.write(key: 'profile_status', value: 'enable');
            await AndroidMethodChannel.to.enableCamera();
          } else {
            await AppConfig.to.storage.write(key: 'profile_status', value: 'disable');
            await AndroidMethodChannel.to.disableCamera();
          }
        }
      }else{

        if(event.tagType == "ENABLE" || event.enabled == true) {
          await AppConfig.to.storage.write(key: 'profile_status', value: 'enable');
        } else {
          await AppConfig.to.storage.write(key: 'profile_status', value: 'disable');
        }
      }
      emit(state.copyWith(status: CommonStatus.success, profileUrl: event.profileUrl, enterPrise: event.enterprise, tag: event.tag));
    }catch (e){
      emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
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
    emit(state.copyWith(status: CommonStatus.loading));
  }

  /// 기능 차단 버튼 클릭 시 다른 MDM 체크
  _onCheckOtherMdm(CheckOtherMdm event, Emitter<HomeState> emit) async {
    // 먼저 상태를 initial로 변경하여 listener가 다시 호출될 수 있도록 함
    // emit(state.copyWith(status: CommonStatus.initial));

    if (Platform.isAndroid) {
      final cameraStatus = await _checkAndroidAdminStatus();
      final tpassStatus = await AppConfig.to.storage.read(key: 'profile_status');

      // 카메라가 restricted이고 TPASS가 차단한 게 아니면 → 다른 MDM
      if (cameraStatus == PermissionStatus.restricted && tpassStatus != 'disable' && tpassStatus != 'wait') {
        emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: cameraStatus, otherMdmDialogShown: true));
        return;
      }
    } else if (Platform.isIOS) {
      final platform = MethodChannel('mguard/ios/mobileconfig');
      try {
        final Map<dynamic, dynamic> blockInfo = await platform.invokeMethod('getCameraBlockSource');
        final String blockSourceStr = blockInfo['blockSource'] ?? 'none';
        logger.d(blockSourceStr);
        if (blockSourceStr == 'otherMdm') {
          emit(state.copyWith(status: CommonStatus.otherMdm, cameraPermissionStatus: PermissionStatus.restricted, otherMdmDialogShown: true));
          return;
        }
      } catch (e) {
        logger.d('iOS getCameraBlockSource 에러: $e');
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
