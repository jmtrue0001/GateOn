import 'dart:async';
import 'dart:io';


import 'package:TPASS/core/core.dart';
import 'package:bloc/bloc.dart';
import "package:convert/convert.dart" show hex;
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:uni_links/uni_links.dart';

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
    on<Manual>(_onManual);
    on<Cancel>(_onCancel);
    on<_TimerTicked>(_onTicked);
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
  }

  final Ticker _ticker;
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
    await AppConfig.to.storage.write(key: 'guide_status', value: 'true');
    final installedTime = await AppConfig.to.storage.read(key: 'time_installed');
    final installedTime2 = await AppConfig.to.shared.getString('time_installed');
    final blockedTime = await AppConfig.to.storage.read(key: 'time_blocked');
    final acceptedTime = await AppConfig.to.storage.read(key: 'time_accepted');
    final code = await AppConfig.to.storage.read(key: 'code');
    final platform =  MethodChannel('mguard/android');
    final initialLink = await getInitialLink();
    var isUninstall = false;
    if(initialLink!= null){
      final uri = Uri.parse(initialLink);
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
      _QrSubscription = linkStream.listen((String? link) {
        if(link != null){
          final uri = Uri.parse(link);
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
    if (code != null) {
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
                   logger.d("삭제방지 ${state.isUninstall}");
                   add(ChangeInstallStatus(isUninstall: false));
                   // logger.d("삭제방지2 ${state.isUninstall}");
                   // if (call.method == "uninstall_canceled") {
                   //   logger.d("삭제방지 ${state.isUninstall}");
                   // }
                   // if (call.method == "update"){
                   //   logger.d("관리자 활성화 성공");
                   //   emit(state.copyWith(isUninstall: false));
                   // }

                 });

    }


    /// 상태 저장
    if(Platform.isAndroid){
      emit(state.copyWith(installedTime: installedTime, cameraPermissionStatus: cameraPermissionStatus, blockedTime: blockedTime, acceptedTime: acceptedTime));
    }else if(Platform.isIOS){
      emit(state.copyWith(installedTime: installedTime2, cameraPermissionStatus: cameraPermissionStatus, blockedTime: blockedTime, acceptedTime: acceptedTime));
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
          (error) async => {
            await AppConfig.to.storage.delete(key: 'code'),
          },
        );
    logger.d(state.enterPrise?.enterpriseFunction?.toJson());
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
        final nfc = NfcManager.instance;
        nfc.startSession(onDiscovered: (NfcTag tag) async {
          if (Platform.isAndroid) {
            Navigator.of(navigatorKey.currentContext!).pop();
          }
          add(TagNFC(tag: tag, enabled: false));
          nfc.stopSession();
        }, onError: (error) async {
          if (Platform.isAndroid) {
            Navigator.of(navigatorKey.currentContext!).pop();
          }
          add(const Cancel());
          nfc.stopSession();
        });
        return;

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
        nfc.startSession(onDiscovered: (NfcTag tag) async {
          if (Platform.isAndroid) {
            Navigator.of(navigatorKey.currentContext!).pop();
          }
          add(TagNFC(tag: tag, enabled: true));
          nfc.stopSession();
        }, onError: (error) async {
          if (Platform.isAndroid) {
            Navigator.of(navigatorKey.currentContext!).pop();
          }
          add(const Cancel());
          nfc.stopSession();
        });
        return;
    /// beacon
      case InteractionType.beacon:
        add(ScanBeacon(state.firstScan));
      /// manual
      case InteractionType.manual:
        add(Manual(enabled: true, code: event.code));
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

    }).catchError((e) {
      emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
    });
  }

  /// 관리자 차단

  /// QR 차단
  _onScanQR(ScanQR event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: CommonStatus.initial));
    String? tagId;
    if(event.barcode == null && event.tagId != null){
      tagId = event.tagId;
    }else if (event.tagId == null && event.barcode != null){
      tagId = Uri.parse(event.barcode!.code!).queryParameters['id'];
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

    }).catchError((error) {
      logger.d(error);  // 에러 로깅
      String errorMessage = error.toString();  // 에러를 문자열로 변환
      add(Error(errorMessage: errorMessage));
      // add(const Error(errorMessage: '차단 QR을 찾을 수 없습니다.\n다시 시도해주세요.'));
    });
  }

  /// NFC 태그
  _onTagNFC(TagNFC event, Emitter<HomeState> emit) async {

    var nfcIdCode = '';
    if (Platform.isAndroid) {
      /// 안드로이드 NDEF 규격 NFC 사용
      Ndef? ndef = Ndef.from(event.tag);
      nfcIdCode = hex.encode(ndef?.additionalData['identifier'] ?? []).toUpperCase();
    } else {
      /// iOS MiFare 규격 NFC 사용
      MiFare? miFare = MiFare.from(event.tag);
      nfcIdCode = hex.encode(miFare?.identifier ?? []).toUpperCase();
    }
    logger.d(nfcIdCode);
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

    }).catchError((error) {
      logger.d(error);
      add(const Error(errorMessage: '차단 NFC을 찾을 수 없습니다.\n다시 시도해주세요.'));
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
        // Future.delayed(const Duration(seconds: 3), () {
        //   if (beaconMatched) return;
        //   add(const Error(errorMessage: '차단 비콘을 찾을 수 없습니다.\n다시 시도해주세요.4'));
        // });
      });
    });
    // emit(state.copyWith(status: CommonStatus.initial));
  }

  /// 비콘 매칭
  _onBeaconMatched(BeaconMatched event, Emitter<HomeState> emit) async {
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
      logger.d("${state.isUninstall} 활성화여부");
    /// 카메라 권한 상태 체크
    await Permission.camera.status.then((cameraPermissionStatus) async {
      /// 안드로이드 디바이스 어드민 상태체크 + 카메라 체크
      if (Platform.isAndroid && state.isUninstall == false) {
        cameraPermissionStatus = await _checkAndroidAdminStatus();
        logger.d('카메라 상태 체크 : ${cameraPermissionStatus}');
      }

      /// 카메라 권한 상태가 변경되었을시
      if (cameraPermissionStatus != state.cameraPermissionStatus) {
        switch (cameraPermissionStatus) {
          case PermissionStatus.granted:
            await AppConfig.to.storage.read(key: 'profile_status').then((value) async {
              logger.d(value);
              switch (value) {
                case 'wait':

                  /// 정상적으로 카메라 차단을 해제함
                  await AppConfig.to.storage.write(key: 'profile_status', value: 'enable');
                  AppConfig.to.storage.write(key: 'time_accepted', value: '${DateTime.now().millisecondsSinceEpoch}');
                  emit(state.copyWith(acceptedTime: '${DateTime.now().millisecondsSinceEpoch}'));
                  break;
                case 'disable':

                  /// 카메라 차단을 해제하고 다시 차단함 (비정상 이용)
                  add(const Ban(error: '3'));
                  break;
                default:
                  break;
              }
            });
            break;
          case PermissionStatus.restricted:

            /// 카메라를 차단함
            await AppConfig.to.storage.write(key: 'profile_status', value: 'disable');
            AppConfig.to.storage.write(key: 'time_blocked', value: '${DateTime.now().millisecondsSinceEpoch}');
            emit(state.copyWith(blockedTime: '${DateTime.now().millisecondsSinceEpoch}'));
            break;
          default:
            add(const Ban(error: '4'));
            break;
        }
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
    await AndroidMethodChannel.to.disableDeviceAdmin();
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
    emit(state.copyWith(status: CommonStatus.initial));
  }
}
