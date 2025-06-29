import 'package:json_annotation/json_annotation.dart';

import '../../core.dart';

part 'generated/secure_model.g.dart';

@JsonSerializable()
class SecureModel {
  LoginStatus loginStatus;
  TokenData tokenData;
  @JsonKey(fromJson: _roleFromJson)
  Role role;
  final String id;

  SecureModel({this.loginStatus = LoginStatus.logout, required this.tokenData, this.role = Role.ROLE_ENTERPRISE, this.id = ''});

  static Role _roleFromJson<T>(dynamic data) {
    return Role.strToEnum(data);
  }

  factory SecureModel.fromJson(Map<String, dynamic> json) => _$SecureModelFromJson(json);

  Map<String, dynamic> toJson() => _$SecureModelToJson(this);
}

@JsonSerializable()
class TokenData {
  String accessToken;
  String fcmToken;
  String deviceId;
  String refreshToken;

  TokenData({this.accessToken = "", this.fcmToken = "", this.refreshToken = "", this.deviceId = ""});

  factory TokenData.fromJson(Map<String, dynamic> json) => _$TokenDataFromJson(json);

  Map<String, dynamic> toJson() => _$TokenDataToJson(this);
}

class EnumData {
  final String code;
  final String displayName;

  EnumData({required this.code, required this.displayName});
}

extension LoginStatusExt on LoginStatus {
  static final _data = {
    LoginStatus.guest: EnumData(code: 'guest', displayName: 'Status_Guest'),
    LoginStatus.login: EnumData(code: 'login', displayName: 'Status_Login'),
    LoginStatus.logout: EnumData(code: 'logout', displayName: 'Status_Logout'),
  };

  static LoginStatus getByCode(String code) {
    try {
      return _data.entries.firstWhere((el) => el.value.code == code).key;
    } catch (e) {
      return LoginStatus.logout;
    }
  }

  String get code => _data[this]!.code;

  String get displayName => _data[this]!.displayName;
}
