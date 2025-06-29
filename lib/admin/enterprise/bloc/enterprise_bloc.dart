import 'dart:typed_data';

import 'package:TPASS/admin/enterprise/repository/enterprise_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

import '../../../core/core.dart';

part 'enterprise_event.dart';
part 'enterprise_state.dart';
part 'generated/enterprise_bloc.g.dart';

class EnterpriseBloc extends Bloc<CommonEvent, EnterpriseState> {
  EnterpriseBloc() : super(const EnterpriseState()) {
    on<Initial>(_onInitial);
    on<Paginate>(_onPaginate);
    on<Detail>(_onDetail);
    on<DetailPaginate>(_onDetailPaginate);
    on<ReInitial>(_onReInitial);
    on<UploadFile>(_onUploadFile);
    on<Add>(_onAdd);
    on<Edit>(_onEdit);
    on<Delete>(_onDelete);
    on<DetailEnterprise>(_onDetailEnterprise);
  }

  _onInitial(Initial event, Emitter<EnterpriseState> emit) async {
    emit(state.copyWith(enterprises: []));
    await EnterpriseApi.to.getEnterprises(1).then((value) => {emit(state.copyWith(status: CommonStatus.success, enterprises: value.data?.items, meta: value.data?.meta, detail: false, uploadStatus: UploadStatus.initial))});
  }

  _onPaginate(Paginate event, Emitter<EnterpriseState> emit) async {
    final users = await EnterpriseApi.to.getEnterprises(event.page ?? 1, query: event.query ?? '', filterType: event.filterType, orderType: event.orderType).catchError((e) {
      emit(state.copyWith(errorMessage: e, status: CommonStatus.failure));
      return e;
    });
    emit(state.copyWith(query: event.query, filterType: event.filterType, orderType: event.orderType, meta: users.data?.meta, status: CommonStatus.success, enterprises: users.data?.items ?? []));
  }

  _onDetail(Detail event, Emitter<EnterpriseState> emit) async {
    await EnterpriseApi.to.enterpriseDetail(event.id).then((value) => emit(state.copyWith(enterprise: value.data?..id = int.parse(event.id))));
    emit(state.copyWith(detail: true));
    await EnterpriseApi.to.getEnterpriseDevices(1, id: event.id).then((value) => emit(state.copyWith(devices: value.data?.items ?? [], detailMeta: value.data?.meta)));
  }

  _onDetailPaginate(DetailPaginate event, Emitter<EnterpriseState> emit) async {
    final value = await EnterpriseApi.to.getEnterpriseDevices(event.page ?? 1, id: event.id ?? '1', query: event.query ?? '', filterType: event.filterType, orderType: event.orderType).catchError((e) {
      emit(state.copyWith(errorMessage: e, status: CommonStatus.failure));
      return e;
    });
    emit(state.copyWith(query: event.query, filterType: event.filterType, orderType: event.orderType, meta: value.data?.meta, status: CommonStatus.success, devices: value.data?.items ?? []));
  }

  _onReInitial(ReInitial event, Emitter<EnterpriseState> emit) {
    emit(state.copyWith(detail: false));
  }

  _onUploadFile(UploadFile event, Emitter<EnterpriseState> emit) {
    emit(state.copyWith(fileBytes: event.fileBytes, extension: event.fileExtension));
  }

  _onAdd(Add event, Emitter<EnterpriseState> emit) async {
    emit(state.copyWith(uploadStatus: UploadStatus.loading));
    await EnterpriseApi.to.addEnterprise(event.data, imageBytes: state.fileBytes, extension: state.extension).then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.success));
      add(const Initial());
    }).catchError((error) {
      emit(state.copyWith(uploadStatus: UploadStatus.failure, errorMessage: error));
      emit(state.copyWith(uploadStatus: UploadStatus.initial));
    });
  }

  _onEdit(Edit event, Emitter<EnterpriseState> emit) async {
    emit(state.copyWith(detail: false, uploadStatus: UploadStatus.loading));
    await EnterpriseApi.to.editEnterprise(event.id, event.data, imageBytes: state.fileBytes, extension: state.extension).then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.success));
      add(const Initial());
    }).catchError((error) {
      emit(state.copyWith(uploadStatus: UploadStatus.failure, errorMessage: error));
      emit(state.copyWith(uploadStatus: UploadStatus.initial));
    });
  }

  _onDelete(Delete event, Emitter<EnterpriseState> emit) async {
    await EnterpriseApi.to.deleteEnterprise(event.id).then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.delete));
      add(const Initial());
    }).catchError((error) {
      emit(state.copyWith(uploadStatus: UploadStatus.failure, errorMessage: error));
    });
  }

  _onDetailEnterprise(DetailEnterprise event, Emitter<EnterpriseState> emit) async {
    final address = event.enterprise.address;
    await EnterpriseApi.to.enterpriseDetail('${event.enterprise.id}').then((value) => emit(state.copyWith(enterprise: value.data?..id = int.parse('${event.enterprise.id}'))));
    emit(state.copyWith(detail: true, enterprise: state.enterprise?.copyWith(address: address)));
    await EnterpriseApi.to.getEnterpriseDevices(1, id: '${event.enterprise.id}').then((value) => emit(state.copyWith(devices: value.data?.items ?? [], detailMeta: value.data?.meta)));
  }
}
