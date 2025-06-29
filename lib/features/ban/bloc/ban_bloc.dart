

import 'dart:io';

import 'package:TPASS/core/core.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

import '../../../main.dart';
import '../../home/repository/home_repository.dart';

part 'ban_event.dart';
part 'ban_state.dart';
part 'generated/ban_bloc.g.dart';

class BanBloc extends Bloc<CommonEvent, BanState> {
  BanBloc() : super(const BanState()) {
    on<Initial>(_onInitial);
  }

  _onInitial(Initial event, Emitter<BanState> emit) async {
    AppConfig.to.storage.write(key: 'profile_status', value: 'ban');
    final installedTime = await AppConfig.to.storage.read(key: 'time_installed');
    final installedTime2 = await AppConfig.to.shared.getString('time_installed');
    await AppConfig.to.storage.read(key: 'code').then((value) async {
      if (value != null) {
        if(Platform.isAndroid){
          emit(state.copyWith(code: value, installedTime: installedTime));
        }else if(Platform.isIOS){
          emit(state.copyWith(code: value, installedTime: installedTime2));
        }

        await HomeRepository.to.checkCode(value).then((value) => emit(state.copyWith(enterPrise: value.data))).catchError((error) => error);
      }
    });
    await AppConfig.to.storage.read(key: 'deviceId').then((value) {
      emit(state.copyWith(deviceId: value));
    });
  }
}
