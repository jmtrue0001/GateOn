import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

import 'login_model.dart';

part 'generated/profile_model.g.dart';

@CopyWith()
@JsonSerializable()
class Enterprise {
  @JsonKey(name: "id")
  int? id;
  @JsonKey(name: "code")
  final String? code;
  @JsonKey(name: "createdAt")
  final String? createdAt;
  @JsonKey(name: "address")
  final String? address;
  @JsonKey(name: "name")
  final String? name;
  @JsonKey(name: "userId")
  final String? userId;
  @JsonKey(name: "enterpriseFile")
  final EnterpriseFile? enterpriseFile;
  @JsonKey(name: "enterpriseLocation")
  final EnterpriseLocation? enterpriseLocation;
  @JsonKey(name: "file")
  final EnterpriseFile? file;
  @JsonKey(name: "location")
  final EnterpriseLocation? location;
  @JsonKey(name: "enterpriseFunction")
  final EnterpriseFunction? enterpriseFunction;

  Enterprise({
    this.id,
    this.code,
    this.createdAt,
    this.name,
    this.userId,
    this.address,
    this.enterpriseFile,
    this.enterpriseLocation,
    this.file,
    this.location,
    this.enterpriseFunction
  });

  factory Enterprise.fromJson(Map<String, dynamic> json) => _$EnterpriseFromJson(json);

  Map<String, dynamic> toJson() => _$EnterpriseToJson(this);
}

@JsonSerializable()
class EnterpriseFile {
  @JsonKey(name: "fileName")
  final String? fileName;
  @JsonKey(name: "fileOriginalName")
  final String? fileOriginalName;
  @JsonKey(name: "fileSize")
  final int? fileSize;

  EnterpriseFile({
    this.fileName,
    this.fileOriginalName,
    this.fileSize,
  });

  factory EnterpriseFile.fromJson(Map<String, dynamic> json) => _$EnterpriseFileFromJson(json);

  Map<String, dynamic> toJson() => _$EnterpriseFileToJson(this);
}

@JsonSerializable()
class EnterpriseLocation {
  @JsonKey(name: "address")
  final String? address;
  @JsonKey(name: "latitude")
  final double? latitude;
  @JsonKey(name: "longitude")
  final double? longitude;
  @JsonKey(name: "radius")
  final int? radius;

  EnterpriseLocation({
    this.address,
    this.latitude,
    this.longitude,
    this.radius,
  });

  factory EnterpriseLocation.fromJson(Map<String, dynamic> json) => _$EnterpriseLocationFromJson(json);

  Map<String, dynamic> toJson() => _$EnterpriseLocationToJson(this);
}
