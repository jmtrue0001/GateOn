import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

import '../../../core/core.dart' hide Detail;
import '../repository/sub_repository.dart';

part 'generated/sub_bloc.g.dart';
part 'sub_event.dart';
part 'sub_state.dart';

class SubBloc extends Bloc<CommonEvent, SubState> {
  SubBloc() : super(const SubState()) {
    on<Initial>(_onInitial);
    on<Paginate>(_onPaginate);
    on<Detail>(_onDetail);
    on<Add>(_onAdd);
    on<Edit>(_onEdit);
    on<Delete>(_onDelete);
    on<Error>(_onError);
  }

  _onInitial(Initial event, Emitter<SubState> emit) async {
    emit(state.copyWith(detail: false, query: '', status: CommonStatus.initial, uploadStatus: UploadStatus.initial));
    add(const Paginate(page: 1));
  }

  _onPaginate(Paginate event, Emitter<SubState> emit) async {
    await SubApi.to.getSubAdminList(event.page ?? 1, query: event.query ?? '', filterType: event.filterType, orderType: event.orderType).then((value) {
      emit(state.copyWith(query: event.query, filterType: event.filterType, orderType: event.orderType, meta: value.data?.meta, status: CommonStatus.success, subAdmins: value.data?.items ?? []));
    }).catchError((e) {
      add(Error(errorMessage: '$e', commonStatus: CommonStatus.failure));
    });
  }

  _onDetail(Detail event, Emitter<SubState> emit) async {
    // await SubApi.to.getSubAdminDetail(event.id).then((value) => emit(state.copyWith(subAdmin: value.data)));
    emit(state.copyWith(detail: true, subAdmin: event.subAdmin));
  }

  _onAdd(Add event, Emitter<SubState> emit) async {
    await SubApi.to.addSubAdmin(event.data).then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.success));
      add(const Initial());
    }).catchError((error) {
      add(Error(errorMessage: '$error', uploadStatus: UploadStatus.failure));
    });
  }

  _onEdit(Edit event, Emitter<SubState> emit) async {
    await SubApi.to.patchSubAdminDetail(event.id ?? '0', event.data).then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.success));
      add(const Initial());
    }).catchError((error) {
      add(Error(errorMessage: '$error', uploadStatus: UploadStatus.failure));
    });
  }

  _onError(Error event, Emitter<SubState> emit) {
    emit(state.copyWith(errorMessage: event.errorMessage, status: event.commonStatus, uploadStatus: UploadStatus.failure));
    emit(state.copyWith(status: CommonStatus.initial, uploadStatus: UploadStatus.initial));
  }

  _onDelete(Delete event, Emitter<SubState> emit) async {
    await SubApi.to.deleteSubAdmin(event.id ?? '0').then((value) {
      emit(state.copyWith(uploadStatus: UploadStatus.success));
      add(const Initial());
    }).catchError((error) {
      add(Error(errorMessage: '$error', uploadStatus: UploadStatus.failure));
    });
  }
}
