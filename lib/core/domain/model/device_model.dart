import 'package:json_annotation/json_annotation.dart';

import 'login_model.dart';

part 'generated/device_model.g.dart';

@JsonSerializable()
class Device {
  @JsonKey(name: "id")
  final int? id;
  final String? createdAt;
  @JsonKey(name: "tagId")
  final String? tagId;
  @JsonKey(name: "type")
  final String? type;
  @JsonKey(name: "changeId")
  final String? changeId;
  @JsonKey(name: "deviceType")
  final String? deviceType;
  @JsonKey(name: "enterprise")
  final EnterpriseInfo? enterprise;
  @JsonKey(name: "deviceActive")
  final bool? deviceActive;

  Device({
    this.id,
    this.createdAt,
    this.tagId,
    this.type,
    this.changeId,
    this.deviceType,
    this.enterprise,
    this.deviceActive
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceToJson(this);
}
