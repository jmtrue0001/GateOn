# MGuard Json Model
MGuard 프로젝트의 `json model`에 대한 문서입니다.

## Json serializable
json 파싱에는 다음과 같은 패키지를 사용합니다.

```yaml
dependencies:
  json_annotation: ^4.7.0
  copy_with_extension: ^5.0.3

dev_dependencies:
  build_runner: ^2.4.4
  json_serializable: ^6.5.4
  copy_with_extension_gen: ^5.0.3

```

- `json_serializable` -> json 파싱에 사용됩니다.
- `copy_with_extension` -> `.copyWith()` 메서드를 사용하기 위해 사용됩니다.

## Json Model

`model`의 경우 다음과 같은 `base`를 기반으로 구성됩니다.

```dart
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
      Alert => Alert.fromJson(data),
      LoginInfo => LoginInfo.fromJson(data),
      bool || int || String => data,
      Type() => null,
    } as T;
  }

  static Map<String, dynamic>? _dataToJson<T>(T? data) {
    return switch (T) {
      Alert => (data as Alert).toJson(),
      bool || int || String => <String, dynamic>{'data': data},
      Type() => null,
    };
  }

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson<T>(json);
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
    if (T == List<Alert>) return json.map((e) => Alert.fromJson(e)).toList() as T;
    return [] as T;
  }

  static List<Map<String, dynamic>?>? _listToJson<T>(T? items) {
    return (items as List)
        .map((element) => switch (element.runtimeType) {
      Alert => (element as Alert).toJson(),
      Type() => null,
    })
        .toList();
  }

  factory Items.fromJson(Map<String, dynamic> json) => _$ItemsFromJson<T>(json);
}
```

- `BaseModel` -> 모든 `model`의 기본이 되는 모델입니다.
- `Model` -> `data`가 포함된 모델입니다.
- `ListModel` -> `data`가 `List`인 모델입니다.

#### 파싱 모델 생성
`Model`과 `ListModel`에 작성된 것을 기준으로 파싱 모델을 생성합니다.

```dart
@JsonSerializable()
class Alert {
  final String? id;
  final String? createdAt;
  final String? type;
  final String? title;
  final String? message;
  final int? linkId;
  final bool? view;

  const Alert({this.id, this.createdAt, this.type, this.title, this.message, this.view, this.linkId});

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);

  Map<String, dynamic> toJson() => _$AlertToJson(this);
}
```
이와 같이 모델을 생성 후 fromJson, toJson 메서드를 `Model.dart`에 추가합니다.
