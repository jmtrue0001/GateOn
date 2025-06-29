import 'dart:io';

import 'package:TPASS/main.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/core.dart';

class HomeRepository with CommonRepository {
  static HomeRepository get to => HomeRepository();

  Future<CodeModel?> getProfileWithDevice(String tagId) async {
    try {
      var result = await post(profileUrl, body: {'deviceId': await AppConfig.to.storage.read(key: "deviceId"), 'tagId': tagId, 'osType': Platform.isAndroid ? "Android" : "IOS"});
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
      var result = await post(locationEnableUrl, body: {'code': code, 'latitude': data.latitude, 'longitude': data.longitude, 'deviceId': await AppConfig.to.storage.read(key: "deviceId"), 'osType': Platform.isAndroid ? "Android" : "IOS"});
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
      var result = await post(profileUrl, body: {'code': code, "enableCode" : await AppConfig.to.storage.read(key: 'code'), "profileType": "Manual", 'deviceId': await AppConfig.to.storage.read(key: "deviceId"), 'osType': Platform.isAndroid ? "Android" : "IOS", 'manualEnabled' : enabled});
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
    var result = await post(enterpriseUrl, param: 'code', body: {'code': code}, loginRequest: false);
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

  Future<bool> disableBan(String? code, String? banCode) async {
    var result = await post(profileUrl, param: 'ban', body: {"deviceId": await AppConfig.to.storage.read(key: "deviceId"), "banCode": banCode, "code": code, 'osType': Platform.isAndroid ? "Android" : "IOS"}, loginRequest: false);
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
}
