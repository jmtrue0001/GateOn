import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../main.dart';
import '../repository/main_repository.dart';

part 'generated/main_bloc.g.dart';
part 'main_event.dart';
part 'main_state.dart';

class MainBloc extends Bloc<CommonEvent, MainState> {
  MainBloc(this.pageController) : super(const MainState()) {
    on<Initial>(_onInitial);
    on<Paginate>(_onPageNate);
    on<LogOut>(_onLogOut);
    on<ChangeAccount>(_onChangeAccount);
  }

  final PageController pageController;

  _onInitial(Initial event, Emitter<MainState> emit) async {
    try {
      var secureString = AppConfig.to.shared.getString('secureInfo');
      var secureData = SecureModel(tokenData: TokenData(), loginStatus: LoginStatus.logout);
      if (secureString != null) {
        secureData = SecureModel.fromJson(jsonDecode(secureString));
      }
      logger.d(secureData.loginStatus);
      if (secureData.loginStatus == LoginStatus.logout) {
        emit(state.copyWith(status: CommonStatus.failure));
      } else {
        await MainApi.to.getEnterpriseData().then((value) => emit(state.copyWith(status: CommonStatus.success, enterpriseInfo: value.data?..loginId = secureData.id)));
        logger.d(" 인포 ${state.enterpriseInfo?.enterpriseFunction?.toJson()}");
      }
    } catch (e) {
      logger.e(e);
      emit(state.copyWith(status: CommonStatus.failure, errorMessage: e.toString()));
      emit(state.copyWith(status: CommonStatus.initial));
    }
  }

  _onPageNate(Paginate event, Emitter<MainState> emit) {
    pageController.jumpToPage(event.page ?? 0);
    emit(state.copyWith(page: event.page));
  }

  _onLogOut(LogOut event, Emitter<MainState> emit) async {
    var secureModel = SecureModel(
      tokenData: TokenData(),
      loginStatus: LoginStatus.logout,
    );
    await AppConfig.to.shared.setString('secureInfo', jsonEncode(secureModel.toJson()));
    // 브라우저 세션 마커 제거(재접속 자동로그인 방지와 일관성 유지).
    clearBrowserSession();
    emit(state.copyWith(status: CommonStatus.failure));
  }

  // 관리자 계정(아이디/비밀번호) 변경. 성공 시 보안상 로그아웃 후 로그인 화면으로 이동한다.
  _onChangeAccount(ChangeAccount event, Emitter<MainState> emit) async {
    await MainApi.to.changeAccount(event.data).then((value) async {
      // 입력 다이얼로그 닫기
      Navigator.pop(navigatorKey.currentContext!);
      // 재로그인 안내 팝업을 먼저 띄운다. (로그아웃보다 먼저 → 팝업이 확실히 노출됨)
      await showAdaptiveDialog(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog.adaptive(
              title: const Text('알림'),
              content: Text('아이디/비밀번호가 변경되었습니다.\n변경된 정보로 다시 로그인해주세요.', style: textTheme(ctx).krBody1),
              actions: <Widget>[
                adaptiveAction(context: ctx, onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
              ],
            );
          });
      // '확인' 후 로그아웃 처리(저장소 + 메모리 + 브라우저 세션) 및 로그인 화면 이동.
      var secureModel = SecureModel(tokenData: TokenData(), loginStatus: LoginStatus.logout);
      await AppConfig.to.shared.setString('secureInfo', jsonEncode(secureModel.toJson()));
      AppConfig.to.secureModel = secureModel;
      clearBrowserSession();
      navigatorKey.currentContext!.go('/login');
    }).catchError((e) {
      showAdaptiveDialog(
          context: navigatorKey.currentContext!,
          builder: (ctx) {
            return AlertDialog.adaptive(
              title: const Text('알림'),
              content: Text(e.toString(), style: textTheme(ctx).krBody1),
              actions: <Widget>[
                adaptiveAction(context: ctx, onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
              ],
            );
          });
    });
  }
}
