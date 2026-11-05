import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generated/history_model.g.dart';

@JsonSerializable()
class History extends Equatable {
  const History({this.id, this.createdAt, this.nfcInfo, this.way, this.classification, this.releaseManager, this.releaseReason});

  final String? id;
  final String? createdAt;
  final String? nfcInfo;
  final String? way;
  final String? classification;

  /// 비정상 해제 담당자 (classification == '비정상 해제' 행에만 값, 그 외 null)
  final String? releaseManager;

  /// 비정상 해제 사유 (classification == '비정상 해제' 행에만 값, 그 외 null)
  final String? releaseReason;

  @override
  List<Object?> get props => [];

  factory History.fromJson(Map<String, dynamic> json) => _$HistoryFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryToJson(this);
}
