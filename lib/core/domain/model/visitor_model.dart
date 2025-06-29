import 'package:json_annotation/json_annotation.dart';

part 'generated/visitor_model.g.dart';

@JsonSerializable()
class VisitorModel {
  @JsonKey(name: "visitDate")
  final DateTime? visitDate;
  @JsonKey(name: "visitorCount")
  final int? visitorCount;
  @JsonKey(name: "visitNumber")
  final int? visitNumber;

  VisitorModel({this.visitDate, this.visitorCount, this.visitNumber});

  factory VisitorModel.fromJson(Map<String, dynamic> json) => _$VisitorModelFromJson(json);

  Map<String, dynamic> toJson() => _$VisitorModelToJson(this);
}
