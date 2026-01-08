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
  const ReInitial();
}

class ExcelDownload extends UserEvent{
  const ExcelDownload();
}

// class VisitorSseDataReceived extends UserEvent {
//   const VisitorSseDataReceived(this.data);
//
//   final VisitorSseData data;
// }