import 'package:json_annotation/json_annotation.dart';

part 'generated/user_model.g.dart';

@JsonSerializable()
class User {
  final int? id;
  final String? disabledAt;
  final String? enabledAt;
  final String? deviceId;
  final bool? isActive;
  final String? type;

  const User({this.id, this.disabledAt, this.enabledAt, this.deviceId, this.isActive, this.type});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@JsonSerializable()
class UserCount {
  int? disabledCnt;
  int? enabledCnt;

  UserCount({this.disabledCnt, this.enabledCnt});

  factory UserCount.fromJson(Map<String, dynamic> json) => _$UserCountFromJson(json);
}
