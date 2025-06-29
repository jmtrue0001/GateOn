part of 'ban_bloc.dart';

@CopyWith()
class BanState extends CommonState {
  const BanState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page,
    super.query,
    this.code,
    this.deviceId,
    this.enterPrise,
    this.installedTime = '',
  });

  final String? code;
  final String? deviceId;
  final Enterprise? enterPrise;
  final String installedTime;

  @override
  List<Object?> get props => [...super.props, code, deviceId, enterPrise, installedTime];
}
