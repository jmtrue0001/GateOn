part of 'sub_bloc.dart';

class SubEvent extends CommonEvent {
  const SubEvent();
}


class DetailPaginate extends SubEvent {
  const DetailPaginate({this.id, this.page, this.query, this.filterType, this.orderType});
  final String? id;
  final int? page;
  final String? query;
  final FilterType? filterType;
  final OrderType? orderType;
}

class Detail extends SubEvent {
  const Detail(this.subAdmin);

  final SubAdmin subAdmin;
}
