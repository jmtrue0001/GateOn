import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

import '../../../core/core.dart';
import '../repository/device_repository.dart';

part 'device_event.dart';
part 'device_state.dart';
part 'generated/device_bloc.g.dart';

class DeviceBloc extends Bloc<CommonEvent, DeviceState> {
  DeviceBloc() : super(const DeviceState()) {
    on<Initial>(_onInitial);
    on<Paginate>(_onPaginate);
    on<Add>(_onAdd);
    on<Edit>(_onEdit);
    on<Delete>(_onDelete);
  }

  _onInitial(Initial event, Emitter<DeviceState> emit) async {

    await DeviceApi.to.getDevices(1).then((value) {
      logger.d(value.data?.items?.first.toJson());
      logger.d(value.data?.meta);
      logger.d(value.data?.items?.first.deviceActive);
      emit(state.copyWith(status: CommonStatus.success, devices: value.data?.items, meta: value.data?.meta));});
  }

  _onAdd(Add event, Emitter<DeviceState> emit) async {
    emit(state.copyWith(uploadStatus: UploadStatus.loading));
    await DeviceApi.to.addDevice(event.data).then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.success));
      add(const Initial());
    }).catchError((error) {
      emit(state.copyWith(uploadStatus: UploadStatus.failure, errorMessage: error));
    });
  }

  _onPaginate(Paginate event, Emitter<DeviceState> emit) async {
    final devices = await DeviceApi.to.getDevices(event.page ?? 1, query: event.query ?? '', filterType: event.filterType, orderType: event.orderType).catchError((e) {
      emit(state.copyWith(errorMessage: e, status: CommonStatus.failure));
      return e;
    });
    emit(state.copyWith(query: event.query, filterType: event.filterType, orderType: event.orderType, meta: devices.data?.meta, status: CommonStatus.success, devices: devices.data?.items ?? []));
  }

  _onEdit(Edit event, Emitter<DeviceState> emit) async {
    emit(state.copyWith(uploadStatus: UploadStatus.loading));
    await DeviceApi.to.editDevice(event.id ?? '0', event.data).then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.success));
      add(const Initial());
    }).catchError((error) {
      emit(state.copyWith(uploadStatus: UploadStatus.failure, errorMessage: error));
    });
  }

  _onDelete(Delete event, Emitter<DeviceState> emit) async {
    emit(state.copyWith(uploadStatus: UploadStatus.loading));
    await DeviceApi.to.deleteDevice(event.id).then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.success));
      add(const Initial());
    }).catchError((error) {
      emit(state.copyWith(uploadStatus: UploadStatus.failure, errorMessage: error));
    });
  }
}
