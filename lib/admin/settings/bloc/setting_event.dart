part of 'setting_bloc.dart';

class SettingEvent extends CommonEvent {
  const SettingEvent();
}

class SearchAddress extends SettingEvent {
  final String address;

  const SearchAddress(this.address);
}

class ChangeRange extends SettingEvent {
  final int meter;

  const ChangeRange(this.meter);
}

class PickFile extends SettingEvent {
  const PickFile(this.fileBytes, this.fileExtension);

  final Uint8List fileBytes;
  final String? fileExtension;
}

class ChangeFunctionSwitch extends SettingEvent {
  const ChangeFunctionSwitch(this.functionSwitch);

  final (bool, bool, bool, bool, bool, bool, bool, bool) functionSwitch;
}

class ChangePassword extends SettingEvent {
  const ChangePassword(this.data);

  final Map<String, dynamic> data;
}

class SelectAddress extends SettingEvent {
  const SelectAddress({required this.index});

  final int index;
}
