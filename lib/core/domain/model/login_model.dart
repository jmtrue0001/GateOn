import 'package:json_annotation/json_annotation.dart';

import '../../core.dart';

part 'generated/login_model.g.dart';

@JsonSerializable()
class LoginInfo {
  String? accessToken;
  String? refreshToken;
  String? username;
  String? nickname;
  String? role;

  LoginInfo({this.accessToken, this.username, this.nickname, this.refreshToken, this.role});

  factory LoginInfo.fromJson(Map<String, dynamic> json) => _$LoginInfoFromJson(json);
}

@JsonSerializable()
class EnterpriseInfo {
  @JsonKey(name: "code")
  final String? code;
  @JsonKey(name: "name")
  final String? name;
  @JsonKey(name: "enterpriseFile")
  final EnterpriseFile? enterpriseFile;
  @JsonKey(name: "enterpriseLocation")
  final EnterpriseLocation? enterpriseLocation;
  final EnterpriseFunction? enterpriseFunction;
  final String? banDisabledCode;
  String? loginId;

  EnterpriseInfo({this.code, this.name, this.enterpriseFile, this.enterpriseLocation, this.enterpriseFunction, this.banDisabledCode, this.loginId});

  factory EnterpriseInfo.fromJson(Map<String, dynamic> json) => _$EnterpriseInfoFromJson(json);

  Map<String, dynamic> toJson() => _$EnterpriseInfoToJson(this);
}

@JsonSerializable()
class EnterpriseFunction {
  @JsonKey(name: "locationEnable")
  final bool? locationEnable;
  @JsonKey(name: "manualDisable")
  final bool? manualDisable;
  @JsonKey(name: "manualEnable")
  final bool? manualEnable;
  @JsonKey(name: "qrDisable")
  final bool? qrDisable;
  @JsonKey(name: "nfcDisable")
  final bool? nfcDisable;
  @JsonKey(name: "nfcEnable")
  final bool? nfcEnable;
  @JsonKey(name: "beaconDisable")
  final bool? beaconDisable;
  @JsonKey(name: "beaconEnable")
  final bool? beaconEnable;
  EnterpriseFunction({
    this.locationEnable,
    this.manualDisable,
    this.beaconDisable,
    this.nfcDisable,
    this.qrDisable,
    this.beaconEnable,
    this.manualEnable,
    this.nfcEnable
  });

  factory EnterpriseFunction.fromJson(Map<String, dynamic> json) => _$EnterpriseFunctionFromJson(json);

  Map<String, dynamic> toJson() => _$EnterpriseFunctionToJson(this);
}
