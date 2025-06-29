import 'package:json_annotation/json_annotation.dart';

import '../../core.dart';

part 'generated/model.g.dart';

@JsonSerializable()
class BaseModel {
  final int? statusCode;
  final String? message;

  const BaseModel({this.statusCode, this.message});

  factory BaseModel.fromJson(Map<String, dynamic> json) => _$BaseModelFromJson(json);
}

@JsonSerializable()
class Model<T> extends BaseModel {
  @JsonKey(toJson: _dataToJson, fromJson: _dataFromJson)
  final T? data;

  const Model({this.data, super.statusCode, super.message});

  static T? _dataFromJson<T>(dynamic data) {
    if (data == null) return null;
    return switch (T) {
      Notification => Notification.fromJson(data),
      User => User.fromJson(data),
      LoginInfo => LoginInfo.fromJson(data),
      EnterpriseInfo => EnterpriseInfo.fromJson(data),
      GeoLocation => GeoLocation.fromJson(data),
      AllCount => AllCount.fromJson(data),
      UserCount => UserCount.fromJson(data),
      CodeModel => CodeModel.fromJson(data),
      Enterprise => Enterprise.fromJson(data),
      SubAdmin => SubAdmin.fromJson(data),
      bool || int || String => data,
      const (List<VisitorModel>) => (data as List<dynamic>).map((e) => VisitorModel.fromJson(e)).toList(),
      Type() => null,
    } as T;
  }

  static Map<String, dynamic>? _dataToJson<T>(T? data) {
    return switch (T) {
      bool || int || String => <String, dynamic>{'data': data},
      Type() => null,
    };
  }

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson<T>(json);

  Map<String, dynamic> toJson() => _$ModelToJson(this);
}

@JsonSerializable()
class ListModel<T> extends BaseModel {
  final Items<T>? data;

  const ListModel({this.data, super.statusCode, super.message});

  factory ListModel.fromJson(Map<String, dynamic> json) => _$ListModelFromJson<T>(json);
}

@JsonSerializable()
class Items<T> {
  @JsonKey(toJson: _listToJson, fromJson: _listFromJson)
  final List<T>? items;
  final Meta? meta;

  const Items({this.items, this.meta});

  static T? _listFromJson<T>(List<dynamic> json) {
    if (json.isEmpty) return null;
    return switch (T) {
      const (List<User>) => json.map((e) => User.fromJson(e)).toList() as T,
      const (List<VisitorModel>) => json.map((e) => VisitorModel.fromJson(e)).toList() as T,
      const (List<History>) => json.map((e) => History.fromJson(e)).toList() as T,
      const (List<Device>) => json.map((e) => Device.fromJson(e)).toList() as T,
      const (List<Enterprise>) => json.map((e) => Enterprise.fromJson(e)).toList() as T,
      const (List<SubAdmin>) => json.map((e) => SubAdmin.fromJson(e)).toList() as T,
      const (List<bool>) || const (List<int>) || const (List<String>) => json as T,
      Type() => null,
    };
  }

  static List<Map<String, dynamic>?>? _listToJson<T>(T? items) {
    return (items as List)
        .map((element) => switch (element.runtimeType) {
              Type() => null,
            })
        .toList();
  }

  factory Items.fromJson(Map<String, dynamic> json) => _$ItemsFromJson<T>(json);
}
