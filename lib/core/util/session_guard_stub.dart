/// 세션 가드 - 웹이 아닌 환경(모바일)용 stub.
///
/// 모바일에는 브라우저 세션 개념이 없으므로 자동로그인 방지 로직과 무관합니다.
/// hasBrowserSession() 은 항상 true 를 반환하여 강제 로그아웃이 발생하지 않게 합니다.

/// 현재 브라우저 세션이 살아있는지 여부. 모바일에서는 항상 true.
bool hasBrowserSession() => true;

/// 현재 브라우저 세션을 "활성" 으로 표시. 모바일에서는 no-op.
void markBrowserSession() {}

/// 브라우저 세션 마커를 제거. 모바일에서는 no-op.
void clearBrowserSession() {}
