import 'package:json_annotation/json_annotation.dart';

part 'generated/geo_model.g.dart';

@JsonSerializable()
class GeoLocation {
  @JsonKey(name: "documents")
  final List<Document>? documents;

  GeoLocation({
    this.documents,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) => _$GeoLocationFromJson(json);

  Map<String, dynamic> toJson() => _$GeoLocationToJson(this);
}

@JsonSerializable()
class Document {
  @JsonKey(name: "address")
  final Address? address;
  @JsonKey(name: "address_name")
  final String? addressName;
  @JsonKey(name: "address_type")
  final String? addressType;
  @JsonKey(name: "road_address")
  final RoadAddress? roadAddress;
  @JsonKey(name: "x")
  final String? x;
  @JsonKey(name: "y")
  final String? y;

  Document({
    this.address,
    this.addressName,
    this.addressType,
    this.roadAddress,
    this.x,
    this.y,
  });

  factory Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentToJson(this);
}

@JsonSerializable()
class Address {
  @JsonKey(name: "address_name")
  final String? addressName;
  @JsonKey(name: "b_code")
  final String? bCode;
  @JsonKey(name: "h_code")
  final String? hCode;
  @JsonKey(name: "main_address_no")
  final String? mainAddressNo;
  @JsonKey(name: "mountain_yn")
  final String? mountainYn;
  @JsonKey(name: "region_1depth_name")
  final String? region1DepthName;
  @JsonKey(name: "region_2depth_name")
  final String? region2DepthName;
  @JsonKey(name: "region_3depth_h_name")
  final String? region3DepthHName;
  @JsonKey(name: "region_3depth_name")
  final String? region3DepthName;
  @JsonKey(name: "sub_address_no")
  final String? subAddressNo;
  @JsonKey(name: "x")
  final String? x;
  @JsonKey(name: "y")
  final String? y;

  Address({
    this.addressName,
    this.bCode,
    this.hCode,
    this.mainAddressNo,
    this.mountainYn,
    this.region1DepthName,
    this.region2DepthName,
    this.region3DepthHName,
    this.region3DepthName,
    this.subAddressNo,
    this.x,
    this.y,
  });

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable()
class RoadAddress {
  @JsonKey(name: "address_name")
  final String? addressName;
  @JsonKey(name: "building_name")
  final String? buildingName;
  @JsonKey(name: "main_building_no")
  final String? mainBuildingNo;
  @JsonKey(name: "region_1depth_name")
  final String? region1DepthName;
  @JsonKey(name: "region_2depth_name")
  final String? region2DepthName;
  @JsonKey(name: "region_3depth_name")
  final String? region3DepthName;
  @JsonKey(name: "road_name")
  final String? roadName;
  @JsonKey(name: "sub_building_no")
  final String? subBuildingNo;
  @JsonKey(name: "underground_yn")
  final String? undergroundYn;
  @JsonKey(name: "x")
  final String? x;
  @JsonKey(name: "y")
  final String? y;
  @JsonKey(name: "zone_no")
  final String? zoneNo;

  RoadAddress({
    this.addressName,
    this.buildingName,
    this.mainBuildingNo,
    this.region1DepthName,
    this.region2DepthName,
    this.region3DepthName,
    this.roadName,
    this.subBuildingNo,
    this.undergroundYn,
    this.x,
    this.y,
    this.zoneNo,
  });

  factory RoadAddress.fromJson(Map<String, dynamic> json) => _$RoadAddressFromJson(json);

  Map<String, dynamic> toJson() => _$RoadAddressToJson(this);
}
