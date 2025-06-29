import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generated/sub_admin_model.g.dart';

@JsonSerializable()
class SubAdmin extends Equatable {
  const SubAdmin({this.nickname, this.username, this.id, this.createdAt, this.password});

  @JsonKey(name: "id")
  final int? id;
  final String? createdAt;
  final String? username;
  final String? nickname;
  final String? password;

  @override
  List<Object?> get props => [];

  factory SubAdmin.fromJson(Map<String, dynamic> json) => _$SubAdminFromJson(json);

  Map<String, dynamic> toJson() => _$SubAdminToJson(this);
}
