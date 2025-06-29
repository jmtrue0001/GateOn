import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';

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
  }

  final PageController pageController;

  _onInitial(Initial event, Emitter<MainState> emit) async {
    try {
      var secureString = AppConfig.to.shared.getString('secureInfo');
      var secureData = SecureModel(tokenData: TokenData(), loginStatus: LoginStatus.logout);
      if (secureString != null) {
        secureData = SecureModel.fromJson(jsonDecode(secureString));
      }
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
    emit(state.copyWith(status: CommonStatus.failure));
  }
}
