/// 브라우저 세션 가드
///
/// 웹에서 "현재 브라우저 세션이 살아있는지"를 sessionStorage 로 판별합니다.
/// - sessionStorage 는 새로고침(F5)에는 유지되지만, 브라우저/탭을 닫으면 사라집니다.
/// - 따라서 "로그인 정보는 남아있는데 브라우저 세션 마커가 없다" = 재접속 상황으로 보고
///   자동로그인을 방지하는 데 사용합니다.
///
/// 웹이 아닌 환경(모바일)에서는 stub 구현이 사용되어 아무 동작도 하지 않습니다.
library session_guard;

export 'session_guard_stub.dart' if (dart.library.html) 'session_guard_web.dart';
