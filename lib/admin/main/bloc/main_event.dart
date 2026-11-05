part of 'main_bloc.dart';

class MainEvent extends CommonEvent {
  const MainEvent();
}

class LogOut extends MainEvent {
  const LogOut();
}

/// 관리자 계정(아이디/비밀번호) 변경 이벤트. data: {username, password}
class ChangeAccount extends MainEvent {
  const ChangeAccount(this.data);

  final Map<String, dynamic> data;
}
