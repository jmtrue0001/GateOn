import 'dart:convert';

import 'package:TPASS/admin/login/repository/login_repository.dart';
import 'package:TPASS/main.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

import '../../../core/core.dart';

part 'generated/login_bloc.g.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<CommonEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<Initial>(_onInitial);
    on<Login>(_onLogin);
  }

  _onInitial(Initial event, Emitter<LoginState> emit) async {
    var secureModel = SecureModel(
      tokenData: TokenData(),
      loginStatus: LoginStatus.logout,
    );
    await AppConfig.to.shared.setString('secureInfo', jsonEncode(secureModel.toJson()));
  }

  _onLogin(Login event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: CommonStatus.initial));
    await LoginApi.to.login(event.id, event.password).then((value) async {
      var accessToken = value.data?.accessToken;
      var refreshToken = value.data?.refreshToken;
      if (accessToken != null) {
        var secureModel = SecureModel(
          loginStatus: LoginStatus.login,
          tokenData: TokenData(
            accessToken: accessToken,
            refreshToken: refreshToken ?? '',
          ),
          role: Role.strToEnum(value.data?.role),
          id: event.id,
        );
        await AppConfig.to.shared.setString('secureInfo', jsonEncode(secureModel.toJson()));
        AppConfig.to.secureModel = secureModel;

        // // SSE 연결 시작
        // SseService.to.connectAll(accessToken);
        // logger.d('SSE connections initialized after login');

        emit(state.copyWith(status: CommonStatus.success));
      }
    }).catchError((e) {
      emit(state.copyWith(status: CommonStatus.failure, errorMessage: e.toString()));
    });
  }
}
