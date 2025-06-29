import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generated/dashboard_model.g.dart';

@JsonSerializable()
class AllCount extends Equatable {
  const AllCount({this.cnt});

  final int? cnt;

  @override
  List<Object?> get props => [];

  factory AllCount.fromJson(Map<String, dynamic> json) => _$AllCountFromJson(json);

  Map<String, dynamic> toJson() => _$AllCountToJson(this);
}
