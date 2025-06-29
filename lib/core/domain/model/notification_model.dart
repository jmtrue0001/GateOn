import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generated/notification_model.g.dart';

@JsonSerializable()
@CopyWith()
class Notification {
  String? title;
  String? body;
  String? id;
  String? type;

  Notification({this.title, this.body, this.id, this.type});

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
}
