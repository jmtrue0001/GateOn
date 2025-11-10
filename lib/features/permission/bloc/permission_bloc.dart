import 'dart:io';

import 'package:TPASS/core/core.dart';
import 'package:TPASS/main.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:permission_handler/permission_handler.dart';

part 'generated/permission_bloc.g.dart';
part 'permission_event.dart';
part 'permission_state.dart';

class PermissionBloc extends Bloc<CommonEvent, PermissionState> {
  PermissionBloc() : super(const PermissionState()) {
    on<Initial>(_onInitial);
    on<AgreeTerm>(_onAgreeTerm);
    on<AgreeAll>(_onAgreeAll);
  }

  _onInitial(Initial event, Emitter<PermissionState> emit) async{
    // var deviceManage = true;
    // if (Platform.isAndroid) {
    //   deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
    //   logger.d(deviceManage);
    //   if (!deviceManage) {
    //     await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
    //       deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
    //     });
    //   }
    //   await AndroidMethodChannel.to.showLicense();
    //   logger.d(deviceManage);
    // }
  }

  _onAgreeTerm(AgreeTerm event, Emitter<PermissionState> emit) {
    if (event.type == TermType.privacy) {
      emit(state.copyWith(privacy: event.agree));
    } else {
      emit(state.copyWith(service: event.agree));
    }
  }

  _onAgreeAll(AgreeAll event, Emitter<PermissionState> emit) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.bluetooth,
      Permission.bluetoothScan,
    ].request();

    var camera = statuses[Permission.camera] ?? PermissionStatus.denied;
    var location = statuses[Permission.locationWhenInUse] ?? PermissionStatus.denied;
    var bluetooth = statuses[Permission.bluetooth] ?? PermissionStatus.denied;
    var deviceManage = true;
    
    if (Platform.isAndroid) {
      // deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
      // logger.d(deviceManage);
      // if (!deviceManage) {
      //   await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
      //     deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
      //   });
      // }
      // await AndroidMethodChannel.to.showLicense();
      // logger.d(deviceManage);
      await AppConfig.to.deviceInfo.androidInfo.then((value) {
        if (value.version.sdkInt >= 31) {
          bluetooth = statuses[Permission.bluetoothScan] ?? PermissionStatus.denied;
        }
      });
    }

    switch ((camera, location, bluetooth, deviceManage)) {
      case (PermissionStatus.restricted, PermissionStatus.granted, PermissionStatus.granted, true):
      case (PermissionStatus.granted, PermissionStatus.granted, PermissionStatus.granted, true):
        emit(state.copyWith(status: CommonStatus.success));
        break;
      case (PermissionStatus.denied, _, _, _):
        camera = await Permission.camera.request();
        if (camera.isGranted && location.isGranted && bluetooth.isGranted) {
          emit(state.copyWith(status: CommonStatus.success));
        } else {
          emit(state.copyWith(status: CommonStatus.failure));
        }
        break;
      case (_, PermissionStatus.denied, _, _):
        location = await Permission.locationWhenInUse.request();
        if (camera.isGranted && location.isGranted && bluetooth.isGranted) {
          emit(state.copyWith(status: CommonStatus.success));
        } else {
          emit(state.copyWith(status: CommonStatus.failure));
        }
        break;
      case (_, _, PermissionStatus.denied, _):
        bluetooth = await Permission.bluetooth.request();
        if (camera.isGranted && location.isGranted && bluetooth.isGranted) {
          emit(state.copyWith(status: CommonStatus.success));
        } else {
          emit(state.copyWith(status: CommonStatus.failure));
        }
        break;
      case (_, _, _, false):
        deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
        logger.d(deviceManage);
        if (!deviceManage) {
          await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
            deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
            if (deviceManage) {
              // final licenseResult = await AndroidMethodChannel.to.showLicense();
              // logger.d(licenseResult);
              // if (licenseResult == true) {
                emit(state.copyWith(status: CommonStatus.success));
              // } else {
              //   emit(state.copyWith(status: CommonStatus.failure));
              // }
            } else {
              emit(state.copyWith(status: CommonStatus.failure));
            }
          });
        }
        break;
      case (_, _, _, _):
        openAppSettings();
        break;
    }
  }
}