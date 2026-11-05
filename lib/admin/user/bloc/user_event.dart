part of 'user_bloc.dart';

class UserEvent extends CommonEvent {
  const UserEvent();
}
class DetailPaginate extends UserEvent {
  const DetailPaginate({this.id, this.page, this.query, this.filterType, this.orderType});
  final String? id;
  final int? page;
  final String? query;
  final FilterType? filterType;
  final OrderType? orderType;
}

class ReInitial extends UserEvent {
  const ReInitial({this.page});
  final int? page;
}

class Initial extends UserEvent {
  const Initial({this.page,});
  final int? page;
}

class ExcelDownload extends UserEvent{
  const ExcelDownload();
}

/// 방문객 리스트 상세 검색. filter를 보관해 이후 페이지네이션에도 유지한다.
class SearchVisitors extends UserEvent {
  const SearchVisitors({required this.filter, this.page = 1, this.count});
  final VisitorFilter filter;
  final int page;
  final int? count;
}

// class VisitorSseDataReceived extends UserEvent {
//   const VisitorSseDataReceived(this.data);
//
//   final VisitorSseData data;
// }