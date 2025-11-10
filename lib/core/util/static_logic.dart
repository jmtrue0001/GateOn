import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/core.dart';

String dateParser(String? date) {
  if (date == null) return "-";
  return DateFormat('yyyy년 MM월 dd일').format(DateTime.parse(date));
}

String dateDataParser({String? dateString, DateTime? date, String format = 'yyyy-MM-dd'}) {
  if (date == null) return "-";
  if (dateString != null) {
    return DateFormat(format).format(DateTime.parse(dateString));
  } else {
    return DateFormat(format).format(date);
  }
}

String timeParser(String? date, bool showCurrentYear, {bool? second}) {
  if (date == null) return "-";
  final dateData = DateTime.parse(date).toLocal();
  if (dateData.year == DateTime.now().year && !showCurrentYear) {
    return DateFormat('MM-dd HH:mm').format(dateData);
  }
  if(second == true) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateData);
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(dateData);
}

String numberFormatter(int? number) {
  if (number == null) {
    return '-';
  }
  return NumberFormat('###,###,###,###').format(number);
}

DateTime dateFormatter(String? date) {
  if (date == null) return DateTime.now().toUtc();
  final result = date.replaceAll("년", "-").replaceAll("월", "-").replaceAll("일", "").replaceAll(" ", "");
  return DateTime.parse(result).toUtc();
}

changeAgeToString(String? age) {
  if (age?.contains("AGERANGE_AGE") ?? false) {
    return "${age?.replaceAll('AGERANGE_AGE_', "").substring(0, 2)}대";
  } else {
    return null;
  }
}

changeGenderToString(String? gender) {
  switch (gender) {
    case "GENDER_MALE":
      return '남';
    case "GENDER_FEMALE":
      return '여';
    default:
      return null;
  }
}

String changeNotificationToString(NotificationType type) {
  switch (type) {
    case NotificationType.notice:
      return "TYPE_NOTICE";
    case NotificationType.event:
      return "TYPE_EVENT";
  }
}

changeEmotionToString(String? emotion) {
  switch (emotion) {
    case "EMOTION_AWESOME":
      return '최고';
    case "EMOTION_GOOD":
      return '좋음';
    case "EMOTION_WELL":
      return '평범';
    case "EMOTION_BAD":
      return '나쁨';
    default:
      return null;
  }
}

changeReactionToString(String? reaction) {
  switch (reaction) {
    case "REACTION_ADOPT":
      return '반영되었어요!';
    case "REACTION_GOOD":
      return '검토중이에요!';
    case "REACTION_WELL":
      return '';
    default:
      return null;
  }
}

checkPermission(Permission permission, BuildContext context, String data) {
  permission.status.then((value) async {
    switch (value) {
      case PermissionStatus.denied:
        await permission.request();
        break;
      case PermissionStatus.permanentlyDenied:
        await deniedPermission(permission, context, data);
        break;
      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.restricted:
      case PermissionStatus.provisional:
        break;
    }
  });
}

deniedPermission(Permission permission, BuildContext context, String data) async {
  permission.request().then((result) {
    if (result == PermissionStatus.permanentlyDenied) {
      showAdaptiveDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog.adaptive(
              title: const Text(
                '알림',
              ),
              content: Text(
                '$data 권한이 거부되어있어요.\n기능 이용을 위해 디바이스 설정에서\n권한 설정을 해야해요. 설정으로 이동할까요?',
                style: textTheme(context).krBody1,
              ),
              actions: <Widget>[
                adaptiveAction(
                  isCancel: true,
                  context: context,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
                adaptiveAction(
                  context: context,
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          });
    }
  }).catchError((error) {
    showAdaptiveDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog.adaptive(
            title: const Text(
              '알림',
            ),
            content: Text(
              '$data 권한이 거부되어있어요.\n기능 이용을 위해 디바이스 설정에서\n권한 설정을 해야해요. 설정으로 이동할까요?',
              style: textTheme(context).krBody1,
            ),
            actions: <Widget>[
              adaptiveAction(
                isCancel: true,
                context: context,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('취소'),
              ),
              adaptiveAction(
                context: context,
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: const Text('확인'),
              ),
            ],
          );
        });
  });
}

String listToString(List<String>? list) {
  String result = "";
  if (list == null) {
    return result;
  }
  for (int i = 0; i < list.length; i++) {
    result += list[i];
    if (i != list.length - 1) {
      result += ",";
    }
  }
  return result;
}
