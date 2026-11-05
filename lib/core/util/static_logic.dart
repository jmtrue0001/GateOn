import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/core.dart';

String dateParser(String? date) {
  if (date == null) return "-";
  return DateFormat('yyyy년 MM월 dd일').format(DateTime.parse(date));
}

/// 업로드한 이미지 바이트가 유효한(정상 디코딩되는) 이미지인지 검증한다.
/// 통과하면 null, 실패하면 안내 메시지를 반환한다.
/// - 빈 파일: 즉시 실패
/// - 확장자만 이미지이고 실제 내용이 손상/비이미지: 디코딩 실패로 걸러냄
Future<String?> validateImageBytes(Uint8List? bytes) async {
  if (bytes == null || bytes.isEmpty) {
    return '유효하지 않은 파일입니다.\n다른 파일을 선택해주세요.';
  }
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (frame.image.width == 0 || frame.image.height == 0) {
      return '손상된 이미지 파일입니다.\n다른 파일을 선택해주세요.';
    }
    return null;
  } catch (_) {
    return '손상되었거나 지원하지 않는 이미지 파일입니다.\n다른 파일을 선택해주세요.';
  }
}

/// 사용자 이름 검증. 규칙: 한글·영문·숫자만 + 2~24자.
String? validateNamePolicy(String name) {
  if (name.length < 2 || name.length > 24) {
    return '사용자 이름은 2자 이상 24자 이하로 입력해주세요.';
  }
  if (!RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(name)) {
    return '사용자 이름은 한글, 영문, 숫자만 입력 가능합니다.';
  }
  return null;
}

/// 업체명 검증. 규칙: 한글·영문·숫자만 + 2~24자.
String? validateEnterpriseNamePolicy(String name) {
  if (name.length < 2 || name.length > 24) {
    return '업체명은 2자 이상 24자 이하로 입력해주세요.';
  }
  if (!RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(name)) {
    return '업체명은 한글, 영문, 숫자만 입력 가능합니다.';
  }
  return null;
}

/// 아이디 검증. 규칙: 영문·숫자만 + 5~12자.
String? validateIdPolicy(String id) {
  if (id.length < 5 || id.length > 12) {
    return '아이디는 영문, 숫자를 포함하여 5자 이상 12자 이하로 입력해주세요.';
  }
  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(id)) {
    return '아이디는 영문, 숫자만 입력 가능합니다.';
  }
  return null;
}

/// 기기 일련번호 검증. 규칙: 영문·숫자만 + 7~24자.
String? validateSerialPolicy(String serial) {
  if (serial.length < 7 || serial.length > 24) {
    return '일련번호는 7자 이상 24자 이하로 입력해주세요.';
  }
  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(serial)) {
    return '일련번호는 영문, 숫자만 입력 가능합니다.';
  }
  return null;
}

/// 비밀번호 정책 안내 문구. 조건 중 하나라도 어기면 전체 조건을 한 번에 안내한다.
const String passwordPolicyMessage =
    '비밀번호는 9자 이상 32자 이하이며,\n영문 대문자, 숫자, 특수문자를 각각 1자 이상 포함해야 합니다.';

/// 비밀번호 복잡도 검증.
/// 규칙: 9~32자 + 영문 대문자 1자 이상 + 숫자 1자 이상 + 특수문자 1자 이상.
/// 특수문자 집합은 서버(AuthService)와 정확히 일치: !@#$%^&*()_+-=[]{};':"\|,.<>/?
/// (프론트에만 있던 ~ ` 는 서버 집합에 없어 제거 — 불일치로 가입/변경이 막히던 문제 방지)
String? validatePasswordPolicy(String password) {
  final bool isValid = password.length >= 9 &&
      password.length <= 32 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]''').hasMatch(password);
  return isValid ? null : passwordPolicyMessage;
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

String typeParser(String? type){
  if(type == "C_DISABLE"){
    return "차단 완료";
  }else if(type == "C_ENABLE"){
    return "해제 완료";
  }else if(type == "T_DISABLE"){
    return "차단 시도";
  }else if(type == "T_ENABLE"){
    return "해제 시도";
  }else if(type == "ABNORMAL"){
    return "비정상 사용";
  }else if(type == "ABNORMAL_RELEASE"){
    return "관리자 해제";
  }else if(type == "DISABLE"){
    return "차단";
  }else if(type == "ENABLE"){
  return "해제";
  }else{
    return '-';
  }
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
