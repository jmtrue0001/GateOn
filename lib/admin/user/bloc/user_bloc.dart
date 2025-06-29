import 'package:TPASS/admin/user/repository/user_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

import '../../../core/core.dart';

part 'generated/user_bloc.g.dart';
part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<CommonEvent, UserState> with StreamTransform {
  UserBloc() : super(const UserState()) {
    on<Initial>(_onInitial);
    on<Paginate>(_onPaginate);
    on<Detail>(_onDetail);
    on<DetailPaginate>(_onDetailPaginate);
    on<ReInitial>(_onReInitial);
  }

  _onInitial(Initial event, Emitter<UserState> emit) async {
    add(const Paginate(page: 1, filterType: FilterType.disabledAt, orderType: OrderType.desc));
    await UserApi.to.statusVisitors().then((value) => emit(state.copyWith(userCount: value.data)));
  }

  _onPaginate(Paginate event, Emitter<UserState> emit) async {
    logger.d(event.filterType);
    logger.d(event.orderType);
    final users = await UserApi.to.getUsers(event.page ?? 1, event.query ?? '', event.filterType, event.orderType).catchError((e) {
      emit(state.copyWith(errorMessage: e, status: CommonStatus.failure));
      return e;
    });
    emit(state.copyWith(query: event.query, filterType: event.filterType, orderType: event.orderType, meta: users.data?.meta, status: CommonStatus.success, users: users.data?.items ?? []));
  }

  _onDetail(Detail event, Emitter<UserState> emit) async {
    await UserApi.to.detailUser(event.id).then((value) => emit(state.copyWith(user: value)));
    emit(state.copyWith(detail: true, filterType: FilterType.none));

    await UserApi.to.userHistory(page: 1, id: event.id).then((value) => emit(state.copyWith(histories: value.data?.items ?? [], detailMeta: value.data?.meta)));

    logger.d(state.histories.last.toJson());
  }

  _onDetailPaginate(DetailPaginate event, Emitter<UserState> emit) async {
    // logger.d(event.page);
    final value = await UserApi.to.userHistory(id: event.id ?? '1', page: event.page ?? 1, query: event.query ?? '', filterType: event.filterType, orderType: event.orderType).catchError((e) {
      emit(state.copyWith(errorMessage: e, status: CommonStatus.failure));
      return e;
    });
    emit(state.copyWith(query: event.query, filterType: event.filterType, orderType: event.orderType, detailMeta: value.data?.meta, status: CommonStatus.success, histories: value.data?.items ?? []));

    logger.d(value.data?.meta?.currentPage);
  }

  _onReInitial(ReInitial event, Emitter<UserState> emit) {
    emit(state.copyWith(detail: false,filterType: FilterType.disabledAt));
  }
}
