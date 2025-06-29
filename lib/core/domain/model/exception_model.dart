import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generated/exception_model.g.dart';

@JsonSerializable()
class ExceptionModel extends Equatable {
  final bool? success;
  final int? statusCode;
  final String? message;

  bool? get exceptionSuccess => success;

  int? get exceptionStatusCode => statusCode;

  String? get exceptionMessage => message;

  const ExceptionModel(this.success, this.statusCode, this.message);

  factory ExceptionModel.fromJson(Map<String, dynamic> json) => _$ExceptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExceptionModelToJson(this);

  @override
  List<Object?> get props => [success, statusCode, message];
}
