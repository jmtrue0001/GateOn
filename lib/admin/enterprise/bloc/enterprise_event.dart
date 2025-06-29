part of 'enterprise_bloc.dart';

class EnterpriseEvent extends CommonEvent {
  const EnterpriseEvent();
}

class DetailEnterprise extends EnterpriseEvent {
  const DetailEnterprise({required this.enterprise});
  final Enterprise enterprise;
}

class DetailPaginate extends EnterpriseEvent {
  const DetailPaginate({this.id, this.page, this.query, this.filterType, this.orderType});
  final String? id;
  final int? page;
  final String? query;
  final FilterType? filterType;
  final OrderType? orderType;
}

class ReInitial extends EnterpriseEvent {
  const ReInitial();
}

class UploadFile extends EnterpriseEvent {
  const UploadFile({required this.fileBytes, this.fileExtension});

  final Uint8List fileBytes;
  final String? fileExtension;
}