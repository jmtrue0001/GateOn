part of 'sub_bloc.dart';

@CopyWith()
class SubState extends CommonState {
  const SubState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page,
    super.meta,
    super.query,
    this.detail = false,
    this.subAdmins = const [],
    this.subAdmin,
    this.detailMeta, this.detailQuery,
    this.uploadStatus = UploadStatus.initial,
  });

  final bool detail;
  final List<SubAdmin> subAdmins;
  final SubAdmin? subAdmin;
  final Meta? detailMeta;
  final String? detailQuery;
  final UploadStatus uploadStatus;

  @override
  List<Object?> get props => [...super.props, detail, subAdmins, subAdmin, uploadStatus];
}
