part of 'home_bloc.dart';

class HomeEvent extends CommonEvent {
  const HomeEvent();
}

class Init extends HomeEvent {
  const Init();
}

class ChangeInstallStatus extends HomeEvent {
  const ChangeInstallStatus({required this.isUninstall});

  final bool isUninstall;
}

class GetEnterPrise extends HomeEvent {
  const GetEnterPrise({this.code});

  final String? code;
}

class SetTicker extends HomeEvent {
  const SetTicker({required this.permissionStatus});

  final PermissionStatus permissionStatus;
}

class DisableDevice extends HomeEvent {
  const DisableDevice(this.interactionType, {this.code});

  final InteractionType interactionType;
  final String? code;
}

class EnableDevice extends HomeEvent {
  const EnableDevice(this.interactionType, {this.code});

  final InteractionType interactionType;
  final String? code;
}

class Manual extends HomeEvent {
  const Manual({this.code, required this.enabled});

  final bool enabled;
  final String? code;
}

class ScanQR extends HomeEvent {
  const ScanQR({this.barcode,this.tagId,this.mode});

  final BarcodeCapture? barcode;
  final String? mode;
  final String? tagId;
}

class TagNFC extends HomeEvent {
  const TagNFC({required this.tag, required this.enabled});

  final NfcTag tag;
  final bool enabled;
}

class Cancel extends HomeEvent {
  const Cancel();
}

class ScanBeacon extends HomeEvent {
  const ScanBeacon(this.firstScan);

  final bool firstScan;
}

class BeaconDetected extends HomeEvent {
  const BeaconDetected(this.result);

  final Map<String, ScanResult> result;
}

class BeaconMatched extends HomeEvent {
  const BeaconMatched(this.data);

  final CodeModel? data;
}

class ActionControl extends HomeEvent {
  const ActionControl({required this.enabled, this.isActive = true, this.enterprise, this.profileUrl, this.tag, this.tagType});

  final bool enabled;
  final bool isActive;
  final Enterprise? enterprise;
  final String? profileUrl;
  final NfcTag? tag;

  final String? tagType;
}

class _TimerTicked extends HomeEvent {
  const _TimerTicked({required this.duration});

  final int duration;
}

class Ban extends HomeEvent {
  const Ban({
    this.error
});

  final String? error;
}
