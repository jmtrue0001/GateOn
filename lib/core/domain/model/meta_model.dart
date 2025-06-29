import 'package:json_annotation/json_annotation.dart';

part 'generated/meta_model.g.dart';

@JsonSerializable()
class Meta {
  int? totalPages;
  int? totalCount;
  int? sizePerPage;
  int? currentPage;

  Meta({this.totalCount, this.sizePerPage, this.currentPage, this.totalPages});

  factory Meta.fromJson(Map<String, dynamic> json) => _$MetaFromJson(json);
}
