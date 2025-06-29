part of 'permission_bloc.dart';

@CopyWith()
class PermissionState extends CommonState {
  const PermissionState({this.privacy = false, this.service = false, super.status = CommonStatus.initial, super.errorMessage = ''});

  final bool privacy;
  final bool service;

  @override
  List<Object?> get props => [...super.props, privacy, service];
}
