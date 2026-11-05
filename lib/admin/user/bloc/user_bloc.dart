import 'dart:async';
import 'package:GateON/admin/user/repository/user_repository.dart';
import 'package:GateON/admin/user/model/visitor_filter.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:flutter/foundation.dart';
import 'web_download_helper.dart' if (dart.library.io) 'stub_download_helper.dart';

import '../../../core/core.dart';

part 'generated/user_bloc.g.dart';
part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<CommonEvent, UserState> with StreamTransform {

  // 현재 적용 중인 상세 검색 필터. 페이지네이션/정렬에도 유지되도록 Bloc에 보관.
  VisitorFilter _filter = const VisitorFilter();

  /// 상세 → 목록 복귀 시 필터 패널 UI를 현재 필터로 복원하기 위한 getter.
  VisitorFilter get currentFilter => _filter;

  UserBloc() : super(const UserState()) {
    on<Initial>(_onInitial);
    on<Paginate>(_onPaginate);
    on<Detail>(_onDetail);
    on<DetailPaginate>(_onDetailPaginate);
    on<ReInitial>(_onReInitial);
    on<ExcelDownload>(_onExcelDownload);
    on<SearchVisitors>(_onSearchVisitors);
  }

  @override
  Future<void> close() {
    return super.close();
  }


  _onInitial(Initial event, Emitter<UserState> emit) async {
    _filter = const VisitorFilter();
    add(const Paginate(page: 1, filterType: FilterType.disabledAt, orderType: OrderType.desc));
    await UserApi.to.statusVisitors().then((value) => emit(state.copyWith(userCount: value.data)));
  }

  _onPaginate(Paginate event, Emitter<UserState> emit) async {
    // 실패 시 예외를 그대로 상태에 넣던 로직을 제거. (errorMessage는 String, users는 목록이라 캐스트 크래시 방지)
    try {
      final users = await UserApi.to.getUsers(event.page ?? 1, event.query ?? '', event.filterType, event.orderType, event.count, filter: _filter);
      emit(state.copyWith(query: event.query, filterType: event.filterType, orderType: event.orderType, meta: users.data?.meta, status: CommonStatus.success, users: users.data?.items ?? []));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString(), status: CommonStatus.failure));
    }
  }

  _onSearchVisitors(SearchVisitors event, Emitter<UserState> emit) async {
    _filter = event.filter;
    // 검색은 항상 1페이지부터, 기존 정렬/개수는 state 값을 유지
    add(Paginate(page: event.page, count: event.count ?? state.meta?.sizePerPage, query: state.query, filterType: state.filterType, orderType: state.orderType));
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

    logger.d("현재페이지 ${value.data?.meta?.currentPage}");
  }

  _onReInitial(ReInitial event, Emitter<UserState> emit) async {
    final page = event.page ?? state.meta?.currentPage ?? 1;
    // 목록으로 돌아올 때 적용 중이던 검색 필터 + 페이지 크기(예: 50개씩 조회)를 유지한다.
    final count = state.meta?.sizePerPage;
    emit(state.copyWith(detail: false, filterType: FilterType.disabledAt));
    add(Paginate(page: page, count: count, filterType: FilterType.disabledAt, orderType: OrderType.desc));
    await UserApi.to.statusVisitors().then((value) => emit(state.copyWith(userCount: value.data)));
  }

  _onExcelDownload(ExcelDownload event, Emitter<UserState> emit){
    try{
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      // 헤더 작성
      sheet.getRangeByName('A1').setText('유저디바이스 ID');
      sheet.getRangeByName('B1').setText('제조사');
      sheet.getRangeByName('C1').setText('제품명');
      sheet.getRangeByName('D1').setText('앱버전');
      sheet.getRangeByName('E1').setText('OS 버전');
      sheet.getRangeByName('F1').setText('차단일시');
      sheet.getRangeByName('G1').setText('허용일시');
      sheet.getRangeByName('H1').setText('정상 이용여부');


      for (int i = 0; i < state.users.length; i++) {
        final row = state.users[i];

        sheet.getRangeByIndex(i + 2, 1).setText('${row.deviceId ?? "-"}');
        sheet.getRangeByIndex(i + 2, 2).setText('${row.osType ?? "-"}');
        sheet.getRangeByIndex(i + 2, 3).setText('${row.deviceModel ?? "-"}');
        sheet.getRangeByIndex(i + 2, 4).setText('${row.osVersion ?? "-"}');
        sheet.getRangeByIndex(i + 2, 5).setText('${row.appVersion ?? "-"}');
        sheet.getRangeByIndex(i + 2, 6).setText('${row.disabledAt ?? "-"}');
        sheet.getRangeByIndex(i + 2, 7).setText('${row.enabledAt ?? "-"}');
        sheet.getRangeByIndex(i + 2, 8).setText(row.isActive == true ? "정상" : "비정상");

      }

      // 2. 엑셀 바이너리로 저장
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // 3. Uint8List로 변환
      final Uint8List dataBytes = Uint8List.fromList(bytes);

      // 4. 플랫폼별 파일 다운로드 처리
      if (kIsWeb) {
        // 웹에서 파일 다운로드 처리 (동적 import 사용)
        _downloadFileOnWeb(dataBytes, "visitors.xlsx");
      } else {
        // 모바일에서는 파일 저장 또는 공유 기능으로 대체
        logger.d("Excel download is only supported on web platform");
      }
    }catch(e){
      logger.d(e);
    }
  }

  // 웹 전용 파일 다운로드 함수
  void _downloadFileOnWeb(Uint8List dataBytes, String fileName) {
    WebDownloadHelper.downloadFile(dataBytes, fileName);
  }
}
