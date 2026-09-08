import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 관리자 웹 세션/자동로그아웃 정책 설정.
///
/// 값은 웹 배포 폴더의 외부 파일 `config.json` 에서 읽어옵니다.
/// (빌드 산출물 `build/web/config.json` 을 재빌드 없이 수정 → 새로고침하면 반영)
///
/// config.json 예시:
/// {
///   "autoLogoutMinutes": 5,        // 무작업 시 자동 로그아웃까지 시간(분). 소수 가능(0.5=30초). 0 이면 자동 로그아웃 비활성화
///   "activityCheckSeconds": 10,    // 사용자 활동 감지 확인 주기(초)
///   "requireLoginOnReopen": true   // 브라우저/탭 닫고 재접속 시 재로그인 필요 여부
/// }
///
/// 파일이 없거나 값이 잘못되면 아래 기본값을 사용합니다.
class SessionConfig {
  SessionConfig._();

  /// 무작업(마우스/키보드 입력 없음) 시 자동 로그아웃까지 시간. (config: autoLogoutMinutes)
  static Duration autoLogoutDuration = const Duration(minutes: 5);

  /// 사용자 활동 감지 확인 주기. (config: activityCheckSeconds)
  static Duration activityCheckInterval = const Duration(seconds: 10);

  /// 브라우저/탭 닫고 재접속 시 재로그인 필요 여부. (config: requireLoginOnReopen)
  static bool requireLoginOnReopen = true;

  /// 외부 `config.json` 을 읽어 위 값들을 덮어씁니다.
  /// 웹에서만 동작하며, 실패 시 기본값을 유지합니다. 앱 시작 시 1회 호출하세요.
  static Future<void> load() async {
    if (!kIsWeb) return;
    try {
      // 캐시 방지용 timestamp 를 붙여 항상 최신 config.json 을 읽습니다.
      final url = Uri.base.resolve('config.json').replace(
        queryParameters: {'ts': '${DateTime.now().millisecondsSinceEpoch}'},
      );
      final res = await http.get(url);
      if (res.statusCode != 200) return;

      final map = jsonDecode(res.body) as Map<String, dynamic>;

      // 0 이면 자동 로그아웃 비활성화(Duration.zero). 음수 등 잘못된 값은 무시하고 기본값 유지.
      final min = map['autoLogoutMinutes'];
      if (min is num && min >= 0) {
        autoLogoutDuration = Duration(milliseconds: (min * 60000).round());
      }

      final chk = map['activityCheckSeconds'];
      if (chk is num && chk > 0) {
        activityCheckInterval = Duration(milliseconds: (chk * 1000).round());
      }

      final reLogin = map['requireLoginOnReopen'];
      if (reLogin is bool) {
        requireLoginOnReopen = reLogin;
      }
    } catch (_) {
      // config.json 이 없거나 파싱 실패 → 기본값 유지
    }
  }
}
