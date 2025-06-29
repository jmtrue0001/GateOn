part of 'device_bloc.dart';

@CopyWith()
class DeviceState extends CommonState {
  const DeviceState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page,
    super.query,
    super.meta,
    this.devices = const [],
    this.uploadStatus = UploadStatus.initial,
  });

  final List<Device> devices;
  final UploadStatus uploadStatus;

  @override
  List<Object?> get props => [...super.props, devices, uploadStatus];
}
