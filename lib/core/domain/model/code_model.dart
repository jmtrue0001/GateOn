import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../core.dart';

part 'generated/code_model.g.dart';

@JsonSerializable()
class CodeModel extends Equatable {
  const CodeModel({this.url, this.enterprise, this.isActive, this.tagType});

  final String? url;
  final bool? isActive;
  final Enterprise? enterprise;
  final String? tagType;

  @override
  List<Object?> get props => [];

  factory CodeModel.fromJson(Map<String, dynamic> json) => _$CodeModelFromJson(json);

  Map<String, dynamic> toJson() => _$CodeModelToJson(this);
}
