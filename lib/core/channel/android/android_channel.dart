
import 'package:TPASS/core/core.dart';
import 'package:flutter/services.dart';

const platform = MethodChannel('mguard/android');

class AndroidMethodChannel {
  static AndroidMethodChannel get to => AndroidMethodChannel();

  //현재 기기권한이 활성화되어 있으면 true를 반환합니다.
  Future<bool> checkDeviceAdminStatus() async {
    try {
      // return await platform.invokeMethod('check_admin') == true;
      return await platform.invokeMethod('check_admin');
    } on PlatformException {
      rethrow;
    }
  }

  Future<bool> checkCameraStatus() async {
    try {
      return await platform.invokeMethod('check_camera') == true;
    } on PlatformException {
      rethrow;
    }
  }

  //기기 권한 활성화

  Future<void> enableDeviceAdmin() async {
    try {
      return await platform.invokeMethod('active');
    } on PlatformException {
      rethrow;
    }
  }

  //기기 권한 강제 활성화
  Future<void> forceDeviceAdmin() async {
    try {
      return await platform.invokeMethod('force_active');
    } on PlatformException {
      rethrow;
    }
  }

  //기기 권한 활성화 해제 후 삭제
  Future<void> disableDeviceAdmin() async {
    try {
      return await platform.invokeMethod('inactive');
    } on PlatformException {
      logger.d('에러');
      rethrow;
    }
  }

  Future<void> disableCamera() async {
    try {
      return await platform.invokeMethod('disable');
    } on PlatformException {
      rethrow;
    }
  }

  Future<bool> enableCamera() async {
    try {
      await platform.invokeMethod('enable');
      return checkCameraStatus();
    } on PlatformException {
      rethrow;
    }
  }

  Future<void> showLicense() async {
    try {
      return await platform.invokeMethod('show_license');
    } on PlatformException {
      rethrow;
    }
  }

  Future<void> uninstallApp() async {
    try {
      return await platform.invokeMethod('uninstall');
    } on PlatformException {
      rethrow;
    }
  }

  Future<String> getId() async {
    try {
      return await platform.invokeMethod('getId');
    }on PlatformException {
      rethrow;
    }
  }



}
