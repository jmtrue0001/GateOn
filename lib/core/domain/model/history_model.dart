import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generated/history_model.g.dart';

@JsonSerializable()
class History extends Equatable {
  const History({this.id, this.createdAt, this.nfcInfo, this.way, this.classification});

  final String? id;
  final String? createdAt;
  final String? nfcInfo;
  final String? way;
  final String? classification;

  @override
  List<Object?> get props => [];

  factory History.fromJson(Map<String, dynamic> json) => _$HistoryFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryToJson(this);
}
