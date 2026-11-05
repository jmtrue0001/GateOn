part of 'ban_bloc.dart';

class BanEvent extends CommonEvent {
  const BanEvent();
}

/// 서버(SSE)로부터 "비정상 해제" 이벤트를 수신했을 때 발생. (관리자 원격 해제)
class Released extends BanEvent {
  const Released();
}
