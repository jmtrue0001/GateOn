part of 'setting_bloc.dart';

@CopyWith()
class SettingState extends CommonState {
  const SettingState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page,
    super.query,
    this.latLng,
    this.address,
    this.meter = 100,
    this.fileBytes,
    this.extension,
    this.functionSwitch = const (false, false, false, false, false, false, false, false),
    this.documents,
    this.document,
  });

  final LatLng? latLng;
  final String? address;
  final int? meter;
  final Uint8List? fileBytes;
  final String? extension;
  final (bool, bool, bool, bool, bool, bool, bool, bool) functionSwitch;
  final List<Document>? documents;
  final Document? document;

  @override
  List<Object?> get props => [...super.props, latLng, address, meter, fileBytes, extension, functionSwitch, documents, document];
}
