/// 세션 가드 - 웹(브라우저)용 구현.
///
/// sessionStorage 를 사용합니다. sessionStorage 는:
/// - 새로고침(F5): 유지됨  → 로그인 유지
/// - 브라우저/탭 닫기 후 재오픈: 사라짐 → 재접속으로 판단하여 자동로그인 방지
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

const String _sessionKey = 'gateon_session_active';

/// 현재 브라우저 세션이 살아있는지 여부.
bool hasBrowserSession() => html.window.sessionStorage[_sessionKey] == 'true';

/// 로그인 성공 시 호출하여 현재 브라우저 세션을 "활성" 으로 표시.
void markBrowserSession() => html.window.sessionStorage[_sessionKey] = 'true';

/// 로그아웃 시 호출하여 브라우저 세션 마커를 제거.
void clearBrowserSession() => html.window.sessionStorage.remove(_sessionKey);
