import 'dart:convert';
import 'dart:typed_data';

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/core.dart';
import '../../../main.dart';
import '../../main/bloc/main_bloc.dart';
import '../repository/setting_repository.dart';

part 'generated/setting_bloc.g.dart';
part 'setting_event.dart';
part 'setting_state.dart';

class SettingBloc extends Bloc<CommonEvent, SettingState> {
  SettingBloc() : super(const SettingState()) {
    on<Initial>(_onInitial);
    on<SearchAddress>(_onSearchAddress);
    on<ChangeRange>(_onChangeRange);
    on<SelectAddress>(_onSelectAddress);
    on<PickFile>(_onPickFile);
    on<Submit>(_onSubmit);
    on<ChangeFunctionSwitch>(_onChangeFunctionSwitch);
    on<ChangePassword>(_onChangePassword);
  }

  _onInitial(Initial event, Emitter<SettingState> emit) {
    final data = event.data;
    if (data is EnterpriseInfo) {
      emit(state.copyWith(
        latLng: LatLng(data.enterpriseLocation?.latitude ?? 37.47, data.enterpriseLocation?.longitude ?? 126.88),
        address: data.enterpriseLocation?.address,
        meter: data.enterpriseLocation?.radius ?? 100,
        functionSwitch: (
        data.enterpriseFunction?.qrDisable ?? false,
        data.enterpriseFunction?.beaconEnable ?? false,
        data.enterpriseFunction?.beaconDisable ?? false,
        data.enterpriseFunction?.locationEnable ?? false,
        data.enterpriseFunction?.nfcDisable ?? false,
        data.enterpriseFunction?.nfcEnable ?? false,
        data.enterpriseFunction?.manualDisable ?? false,
        data.enterpriseFunction?.manualEnable ?? false,
        ),
      ));
    }
    logger.d(state.functionSwitch);
  }

  _onSearchAddress(SearchAddress event, Emitter<SettingState> emit) async {
    await SettingApi.to.getGeo(event.address).then((value) {
      logger.d(value);
      emit(state.copyWith(documents: value.documents));
    });
  }

  _onChangeRange(ChangeRange event, Emitter<SettingState> emit) {
    emit(state.copyWith(meter: event.meter));
  }

  _onPickFile(PickFile event, Emitter<SettingState> emit) async {
    emit(state.copyWith(fileBytes: event.fileBytes, extension: event.fileExtension));
  }

  _onSubmit(Submit event, Emitter<SettingState> emit) async {
    await SettingApi.to.submit(event.data, imageBytes: state.fileBytes, extension: state.extension).then((value) {
      BlocProvider.of<MainBloc>(event.context!).add(const Initial());
      emit(state.copyWith(status: CommonStatus.success));
      return emit(state.copyWith(status: CommonStatus.initial));
    }).catchError((e) {
      emit(state.copyWith(status: CommonStatus.failure, errorMessage: e.toString()));
      emit(state.copyWith(status: CommonStatus.initial));
    });
  }

  _onChangeFunctionSwitch(ChangeFunctionSwitch event, Emitter<SettingState> emit) {
    logger.d(event.functionSwitch);
    emit(state.copyWith(functionSwitch: event.functionSwitch));
  }

  _onChangePassword(ChangePassword event, Emitter<SettingState> emit) async {
    await SettingApi.to.submitIdPw(event.data, imageBytes: []).then((value) async {
      Navigator.pop(navigatorKey.currentContext!);
      var secureModel = SecureModel(
        tokenData: TokenData(),
        loginStatus: LoginStatus.logout,
      );
      await AppConfig.to.shared.setString('secureInfo', jsonEncode(secureModel.toJson())).then((value) {
        showAdaptiveDialog(
            context: navigatorKey.currentContext!,
            builder: (ctx) {
              return AlertDialog.adaptive(
                title: const Text(
                  '알림',
                ),
                content: Text(
                  '저장되었습니다.',
                  style: textTheme(ctx).krBody1,
                ),
                actions: <Widget>[
                  adaptiveAction(
                    context: ctx,
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: const Text('확인'),
                  ),
                ],
              );
            });
        navigatorKey.currentContext!.go('/login');
      });

      emit(state);
    }).catchError((e) {
      emit(state.copyWith(status: CommonStatus.failure, errorMessage: e.toString()));
      emit(state.copyWith(status: CommonStatus.initial));
    });
  }

  _onSelectAddress(SelectAddress event, Emitter<SettingState> emit) {
    final document = state.documents?[event.index];
    emit(state.copyWith(document: document, documents: []));
    emit(state.copyWith(latLng: LatLng(double.parse(state.document?.y ?? '37.47'), double.parse(state.document?.x ?? '126.88')), address: state.document?.roadAddress?.addressName));
  }

  static LatLng convertNaverCoordinates(String mapx, String mapy) {
    double longitude = double.parse(mapx) / 10000000.0;
    double latitude = double.parse(mapy) / 10000000.0;
    return LatLng(latitude, longitude);
  }
}
