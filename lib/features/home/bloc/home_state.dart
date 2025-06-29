part of 'home_bloc.dart';

@CopyWith()
class HomeState extends CommonState {
  const HomeState({
    super.status,
    super.errorMessage = '카메라 권한 제어 중 오류가 발생하였습니다.\n관리자에게 문의해주세요.',
    this.installedTime = '',
    this.cameraPermissionStatus = PermissionStatus.denied,
    this.tag,
    this.tickerStatus = TickerStatus.initial,
    this.duration = 0,
    this.acceptedTime = '',
    this.blockedTime = '',
    this.profileUrl = '',
    this.timeAgo = '',
    this.enterPrise,
    this.scanResult = const {},
    this.firstScan = true,
    this.ban,
    this.isUninstall = false,
    this.qr
  });

  final String installedTime;
  final String blockedTime;
  final String acceptedTime;
  final String? ban;
  final PermissionStatus cameraPermissionStatus;
  final NfcTag? tag;
  final TickerStatus tickerStatus;
  final int duration;
  final String timeAgo;
  final String profileUrl;
  final Enterprise? enterPrise;
  final Map<String, ScanResult> scanResult;
  final bool firstScan;
  final bool isUninstall;
  final String? qr;

  @override
  List<Object?> get props => [
        ...super.props,
        ban,
        installedTime,
        cameraPermissionStatus,
        tag,
        tickerStatus,
        duration,
        acceptedTime,
        blockedTime,
        profileUrl,
        timeAgo,
        enterPrise,
        scanResult,
        firstScan,
        isUninstall,
        qr
      ];
}
