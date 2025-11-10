import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../../core/core.dart';
import '../../../main.dart';
import 'package:html/parser.dart' show parse;
import 'package:version/version.dart';

part 'generated/splash_bloc.g.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<CommonEvent, SplashState> {
  SplashBloc() : super(const SplashState()) {
    on<Initial>(_onInitial);
  }

  Future<dynamic> _getiOSStoreVersion(PackageInfo packageInfo) async {
    try{
      final id = packageInfo.packageName;

      final parameters = {"bundleId": "$id","country" : "KR"};
      var uri = Uri.https("itunes.apple.com", "/lookup", parameters);
      final response = await http.get(uri);
      // logger.d(response.statusCode);
      // logger.d(uri);
      if (response.statusCode != 200) {
        return "";
      }
      if (response.statusCode == 200) {
        final jsonObj = json.decode(response.body);
        if (jsonObj['resultCount'] > 0) {
          return jsonObj['results'][0]['version'];
        } else {
          // 결과가 없는 경우
          return null;
        }
      }

      /* 일반 print에서 일정 길이 이상의 문자열이 들어왔을 때,
     해당 길이만큼 문자열이 출력된 후 나머지 문자열은 잘린다.
     debugPrint의 경우 일반 print와 달리 잘리지 않고 여러 행의 문자열 형태로 출력된다. */

      // debugPrint(response.body.toString());
    }catch(e){
      logger.d(e);
    }

  }

  Future<String?> _getAndroidStoreVersion(
      PackageInfo packageInfo) async {
    try{
      final http.Response _response = await http.get(Uri.parse(
          "https://play.google.com/store/apps/details?id=${packageInfo.packageName}&gl=US"));
      if (_response.statusCode == 200) {
        RegExp regexp =
        RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
        String? _version = regexp.firstMatch(_response.body)?.group(1);
        return _version;
      }
    }catch(e){
      logger.d(e);
    }
  }

  String? getStoreUrlValue(String packageName, String appName) {
    if (Platform.isAndroid) {
      logger.d("https://play.google.com/store/apps/details?id=$packageName");
      return "https://play.google.com/store/apps/details?id=$packageName";
    } else if (Platform.isIOS)
      return "http://apps.apple.com/kr/app/$appName/id6451189407";
    else
      return null;
  }

  _onInitial(Initial event, Emitter<SplashState> emit) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      /* ***************************************** */
      // playStore || appStore -> version check
      /* ***************************************** */

      var storeVersion = Platform.isAndroid ? await _getAndroidStoreVersion(packageInfo) : Platform.isIOS ? await _getiOSStoreVersion(packageInfo) : "";

      logger.d('my device version : ${packageInfo.version}');
      logger.d('current store version: ${storeVersion.toString()}');

      if (storeVersion != null && storeVersion.toString().isNotEmpty && storeVersion.toString().compareTo("") != 0 && Version.parse(storeVersion) > Version.parse(packageInfo.version) ) {
        emit(state.copyWith(status: CommonStatus.failure,errorMessage: getStoreUrlValue(packageInfo.packageName, packageInfo.appName) ));
      }else{
        // final guide = await AppConfig.to.storage.read(key: 'guide_status') == 'true';
        final profileStatus = await AppConfig.to.storage.read(key: 'profile_status');
        if (profileStatus == 'ban') {
          emit(state.copyWith(status: CommonStatus.success, route: '/ban'));
          return;
        }
        // if (!guide) {
        //   emit(state.copyWith(status: CommonStatus.success, route: '/permission'));
        // } else {
        //
        //

        var deviceManage = true;
        if (Platform.isAndroid) {
          deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
          logger.d(deviceManage);
          if (!deviceManage) {
            await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
              deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
            });
          }
          await AndroidMethodChannel.to.showLicense();
          logger.d(deviceManage);
        }
        Map<Permission, PermissionStatus> statuses = await [
          Permission.locationWhenInUse,
          Permission.camera,
          Permission.bluetooth,
          Permission.bluetoothScan,
        ].request();

        var camera = statuses[Permission.camera] ?? PermissionStatus.denied;
        var location = statuses[Permission.locationWhenInUse] ?? PermissionStatus.denied;
        var bluetooth = statuses[Permission.bluetooth] ?? PermissionStatus.denied;
        if (Platform.isAndroid) {
          await AppConfig.to.deviceInfo.androidInfo.then((value) {
            if (value.version.sdkInt >= 31) {
              bluetooth = statuses[Permission.bluetoothScan] ?? PermissionStatus.denied;
            }
          });
        }
        switch ((camera, location, bluetooth, deviceManage)) {
          case (PermissionStatus.restricted, PermissionStatus.granted, PermissionStatus.granted, true):
            emit(state.copyWith(status: CommonStatus.initial));
          case (PermissionStatus.granted, PermissionStatus.granted, PermissionStatus.granted, true):
          await Permission.camera.status.then((value) {
            if (value.isRestricted) {
              switch (profileStatus) {
                case 'disable':
                case 'wait':

                /// 차단 프로파일 설치 및 카메라 차단
                  emit(state.copyWith(status: CommonStatus.success, route: '/'));
                  break;
                case 'enable':

                /// 허용 프로파일 미 설치 및 카메라 차단
                  emit(state.copyWith(status: CommonStatus.success, route: '/'));
                  break;
                default:

                /// 권한이 차단되어있으나 프로파일에 에러가 발생
                  emit(state.copyWith(status: CommonStatus.success, route: '/error/er200'));
                  break;
              }
            } else if (value.isGranted) {
              switch (profileStatus) {
                case 'disable':

                /// 허용 프로파일 미 설치 및 카메라 허용
                  emit(state.copyWith(status: CommonStatus.success, route: '/'));
                  break;
                case 'enable':
                case 'wait':
                case null:

                /// 허용 프로파일 설치 및 카메라 허용
                /// 프로파일 미설치 시
                  emit(state.copyWith(status: CommonStatus.success, route: '/'));
                  break;
                default:

                /// 권한이 허용되어있으나 프로파일에 에러가 발생
                  emit(state.copyWith(status: CommonStatus.success, route: '/error/er300'));
                  break;
              }
            } else {
              /// 권한 정보가 잘못 되었을 때 초기화
              emit(state.copyWith(status: CommonStatus.success, route: '/permission'));
            }
          }).catchError((e) {

            emit(state.copyWith(status: CommonStatus.success, route: '/error/er500'));
            // emit(state.copyWith(status: CommonStatus.error, errorMessage: e.toString()));
          });
            break;
          case (PermissionStatus.denied, _, _, _):
            camera = await Permission.camera.request();
            if (camera.isGranted && location.isGranted && bluetooth.isGranted) {
              emit(state.copyWith(status: CommonStatus.success, route: '/permission'));
            } else {
              emit(state.copyWith(status: CommonStatus.initial));
            }
            break;
          case (_, PermissionStatus.denied, _, _):
            location = await Permission.locationWhenInUse.request();
            if (camera.isGranted && location.isGranted && bluetooth.isGranted) {
              emit(state.copyWith(status: CommonStatus.success, route: '/permission'));
            } else {
              emit(state.copyWith(status: CommonStatus.initial));
            }
            break;
          case (_, _, PermissionStatus.denied, _):
            bluetooth = await Permission.bluetooth.request();
            if (camera.isGranted && location.isGranted && bluetooth.isGranted) {
              emit(state.copyWith(status: CommonStatus.success, route: '/permission'));
            } else {
              emit(state.copyWith(status: CommonStatus.initial));
            }
            break;
          case (_, _, _, false):
            deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
            logger.d(deviceManage);
            if (!deviceManage) {
              await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
                deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
                if (deviceManage) {
                  emit(state.copyWith(status: CommonStatus.success, route: '/permission'));
                } else {
                  emit(state.copyWith(status: CommonStatus.initial));
                }
              });
            }else {
              emit(state.copyWith(status: CommonStatus.success, route: '/permission'));
            }
            break;
          case (_, _, _, _):
            openAppSettings();
            break;
        }
        // }

      }



    } catch (e) {
      emit(state.copyWith(status: CommonStatus.success, route: '/error/er500'));
      // emit(state.copyWith(status: CommonStatus.error, errorMessage: '${e.toString()}'));
    }
  }
}
