import 'dart:io';

import 'package:GateON/main.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/core.dart';

class HomeRepository with CommonRepository {
  static HomeRepository get to => HomeRepository();

  Future<CodeModel?> getProfileWithDevice(String tagId, {String? action}) async {
    try {
      logger.d("보낼때 tagid $tagId");
      var result = await post(profileUrl, body: {'deviceId': await AppConfig.getDeviceId(),  'tagId': tagId, if (action != null) 'action': action, 'osType': Platform.isAndroid ? "SAMSUNG" : "APPLE", 'deviceModel' : AppConfig.to.model, 'osVersion' : AppConfig.to.osVersion, 'appVersion' : AppConfig.to.appVersion});
      switch (result.$1) {
        case StatusCode.success:
          return Model<CodeModel>.fromJson(result.$2).data;
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }

  Future<CodeModel?> getProfileWithLocation(String code) async {
    try {
      var data = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      var result = await post(locationEnableUrl, body: {'code': code, 'latitude': data.latitude, 'longitude': data.longitude, 'deviceId': await AppConfig.getDeviceId(), 'osType': Platform.isAndroid ? "SAMSUNG" : "APPLE",'deviceModel' : AppConfig.to.model, 'osVersion' : AppConfig.to.osVersion, 'appVersion' : AppConfig.to.appVersion});
      switch (result.$1) {
        case StatusCode.success:
          return Model<CodeModel>.fromJson(result.$2).data;
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }

  Future<CodeModel?> getProfileWithManual(String code, bool enabled) async {
    try {
      var result = await post(profileUrl, body: {'code': code, "enableCode" : await AppConfig.to.storage.read(key: 'code'), "profileType": "Manual", 'deviceId': await AppConfig.getDeviceId(), 'osType': Platform.isAndroid ? "SAMSUNG" : "APPLE", 'manualEnabled' : enabled,'deviceModel' : AppConfig.to.model, 'osVersion' : AppConfig.to.osVersion, 'appVersion' : AppConfig.to.appVersion});
      switch (result.$1) {
        case StatusCode.success:
          return Model<CodeModel>.fromJson(result.$2).data;
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }

  Future<Model<Enterprise>> checkCode(String? code) async {
    var result = await post(enterpriseUrl, param: 'code', body: {'code': code,}, loginRequest: false);
    switch (result.$1) {
      case StatusCode.success:
        return Model<Enterprise>.fromJson(result.$2);
      case StatusCode.unAuthorized:
      case StatusCode.notFound:
      case StatusCode.badRequest:
      case StatusCode.forbidden:
      case StatusCode.timeout:
      case StatusCode.error:
        throw result.$2;
    }
  }

  Future<bool> disableBan(String? code, String? banCode, {String? manager, String? reason}) async {
    var result = await post(profileUrl, param: 'ban', body: {"deviceId": await AppConfig.getDeviceId(), 'deviceModel' : AppConfig.to.model, 'osVersion' : AppConfig.to.osVersion, 'appVersion' : AppConfig.to.appVersion, "banCode": banCode, "code": code, 'osType': Platform.isAndroid ? "SAMSUNG" : "APPLE", if (manager != null) "manager": manager, if (reason != null) "reason": reason}, loginRequest: false);
    switch (result.$1) {
      case StatusCode.success:
        return true;
      case StatusCode.unAuthorized:
      case StatusCode.notFound:
      case StatusCode.badRequest:
      case StatusCode.forbidden:
      case StatusCode.timeout:
      case StatusCode.error:
        throw result.$2;
    }
  }

  Future<bool> registerAbnormal(String? code) async {
    var result = await post(profileUrl, param: 'abnormal', body: {"deviceId": await AppConfig.getDeviceId(), 'deviceModel' : AppConfig.to.model, 'osVersion' : AppConfig.to.osVersion, 'appVersion' : AppConfig.to.appVersion, "code": code, 'osType': Platform.isAndroid ? "SAMSUNG" : "APPLE"}, loginRequest: false);
    switch (result.$1) {
      case StatusCode.success:
        return true;
      case StatusCode.unAuthorized:
      case StatusCode.notFound:
      case StatusCode.badRequest:
      case StatusCode.forbidden:
      case StatusCode.timeout:
      case StatusCode.error:
        throw result.$2;
    }
  }

  Future<void> updateProfileInstalled(String uuid, bool profileInstalled, String type) async {
    final code = await AppConfig.to.storage.read(key: 'last_action_code');
    var result = await post(profileUrl, param: 'profileinstalled', body: {
      "deviceId": uuid,
      "profileInstalled" :  profileInstalled,
      "type" : type,
      "enterpriseCode": code,
      // iOS만 프로파일 설치/삭제를 기록, Android는 카메라 직접 제어라 프로파일 기록 불필요
      "profileType": Platform.isIOS ? "INSTALL" : null,
    }, loginRequest: false);
    switch (result.$1) {
      case StatusCode.success:
        return result.$2;
      case StatusCode.unAuthorized:
      case StatusCode.notFound:
      case StatusCode.badRequest:
      case StatusCode.forbidden:
      case StatusCode.timeout:
      case StatusCode.error:
        throw result.$2;
    }
  }

  Future<bool> getProfileInstalled(String uuid) async {
    var result = await get(profileUrl, param: 'profileinstalled?deviceId=${uuid}');
    switch (result.$1) {
      case StatusCode.success:
        return result.$2['data'];
      case StatusCode.unAuthorized:
      case StatusCode.notFound:
      case StatusCode.badRequest:
      case StatusCode.forbidden:
      case StatusCode.timeout:
      case StatusCode.error:
        throw result.$2;
    }
  }

  /// 기기 밴/정상 상태 조회. 반환 true=해제(정상), false=밴. (SSE 초기 진실/폴백용)
  /// GET /device/status?deviceId=&code=  →  { data: <isActive bool> }
  Future<bool> getDeviceActive(String deviceId, String? code) async {
    final query = 'deviceId=$deviceId${(code != null && code.isNotEmpty) ? '&code=$code' : ''}';
    var result = await get(deviceUrl, param: 'status', query: query);
    switch (result.$1) {
      case StatusCode.success:
        return result.$2['data'] ?? false;
      case StatusCode.unAuthorized:
      case StatusCode.notFound:
      case StatusCode.badRequest:
      case StatusCode.forbidden:
      case StatusCode.timeout:
      case StatusCode.error:
        throw result.$2;
    }
  }
}
