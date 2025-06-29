part of 'enterprise_bloc.dart';

@CopyWith()
class EnterpriseState extends CommonState {
  const EnterpriseState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page,
    super.query,
    super.meta,
    this.enterprises = const [],
    this.detail = false,
    this.enterprise,
    this.devices = const [],
    this.detailMeta,
    this.detailQuery,
    this.fileBytes,
    this.extension,
    this.uploadStatus = UploadStatus.initial,
  });

  final List<Enterprise> enterprises;
  final bool detail;
  final Enterprise? enterprise;
  final List<Device> devices;
  final Meta? detailMeta;
  final String? detailQuery;
  final Uint8List? fileBytes;
  final String? extension;
  final UploadStatus uploadStatus;

  @override
  List<Object?> get props => [...super.props, enterprises, detail, enterprise, devices, fileBytes, extension, uploadStatus];
}
