part of 'login_bloc.dart';

class LoginEvent extends CommonEvent {
  const LoginEvent();
}

class Login extends LoginEvent {
  const Login(this.id, this.password);

  final String id;
  final String password;
}