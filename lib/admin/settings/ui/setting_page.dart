import 'dart:math';

import 'package:TPASS/admin/settings/widget/setting_dialog.dart';
import 'package:TPASS/core/core.dart';
import 'package:TPASS/core/widget/input_widget.dart';
import 'package:TPASS/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../main/bloc/main_bloc.dart';
import '../../widget/admin_widget.dart';
import '../bloc/setting_bloc.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController address = TextEditingController();
    final TextEditingController meter = TextEditingController();
    final TextEditingController codeController = TextEditingController();
    final TextEditingController secretCodeController = TextEditingController();
    late GoogleMapController mapController;

    return LayoutBuilder(builder: (context, constraints) {
      final double width = (constraints.maxWidth) - 64;
      final double minHeight = constraints.maxWidth / 1.8;
      return BlocBuilder<MainBloc, MainState>(
        builder: (context, mainState) {
          return BlocProvider(
            create: (context) => SettingBloc(),
            child: BlocListener<SettingBloc, SettingState>(
              listenWhen: (prev, curr) => prev.latLng != curr.latLng || prev.status != curr.status,
              listener: (context, state) {
                mapController.animateCamera(CameraUpdate.newLatLngZoom(state.latLng ?? const LatLng(37.47, 126.88), 15));
                meter.text = (state.meter ?? 1).toString();
                if (state.status == CommonStatus.success) {
                  showAdaptiveDialog(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog.adaptive(
                          title: const Text(
                            '알림',
                          ),
                          content: Text(
                            '저장되었습니다.',
                            style: textTheme(context).krBody1,
                          ),
                          actions: <Widget>[
                            adaptiveAction(
                              context: context,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      });
                } else if (state.status == CommonStatus.failure) {
                  showAdaptiveDialog(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog.adaptive(
                          title: const Text(
                            '알림',
                          ),
                          content: Text(
                            state.errorMessage ?? '저장에 실패하였습니다.',
                            style: textTheme(context).krBody1,
                          ),
                          actions: <Widget>[
                            adaptiveAction(
                              context: context,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      });
                }
              },
              child: StatsTitleWidget(
                text: '시스템 설정',
                buttons: const [],
                child: Wrap(
                  spacing: 32,
                  runSpacing: 32,
                  children: [
                    DataTileContainer(
                        minHeight: minHeight,
                        width: width,
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('기능 허용 GPS 범위 ${AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE ? '설정' : ''}', style: textTheme(context).krSubtitle1),
                                      const SizedBox(height: 32),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('주소', style: textTheme(context).krBody1),
                                          const SizedBox(height: 8),
                                          BlocBuilder<SettingBloc, SettingState>(
                                            buildWhen: (prev, curr) => prev.address != curr.address,
                                            builder: (context, state) {
                                              address.text = state.address ?? '';
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: InputWidget(
                                                      height: 40,
                                                      enabled: AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE,
                                                      filled: AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE_SUB,
                                                      controller: address,
                                                    ),
                                                  ),
                                                  if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) const SizedBox(width: 16),
                                                  if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE)
                                                    InkWell(
                                                      onTap: () => context.read<SettingBloc>().add(SearchAddress(address.text)),
                                                      child: Container(
                                                        height: 40,
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(8),
                                                          color: blue1,
                                                        ),
                                                        child: Center(
                                                          child: Text('검색', style: textTheme(context).krSubtext1B.copyWith(color: white)),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE)
                                        BlocBuilder<SettingBloc, SettingState>(
                                          builder: (context, state) {
                                            return AnimatedContainer(
                                                alignment: Alignment.centerLeft,
                                                margin: state.documents?.isEmpty ?? true ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                                                duration: const Duration(milliseconds: 300),
                                                height: state.documents?.isEmpty ?? true ? 0 : ((state.documents ?? []).take(5).length * 40),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: (state.documents ?? []).take(5).map((document) {
                                                      return SizedBox(
                                                          height: 40,
                                                          child: TextButton(
                                                              onPressed: () {
                                                                FocusScopeNode currentFocus = FocusScope.of(context);
                                                                if (!currentFocus.hasPrimaryFocus) {
                                                                  currentFocus.unfocus();
                                                                }
                                                                address.text = document.roadAddress?.addressName ?? '';
                                                                context.read<SettingBloc>().add(SelectAddress(index: (state.documents ?? []).indexWhere((element) => element == document)));
                                                              },
                                                              child: Text(document.roadAddress?.addressName ?? '', style: textTheme(context).krBody1)));
                                                    }).toList(),
                                                  ),
                                                ));
                                          },
                                        ),
                                      const SizedBox(height: 24),
                                      Text('차단 범위(미터)', style: textTheme(context).krBody1),
                                      const SizedBox(height: 8),
                                      BlocBuilder<SettingBloc, SettingState>(
                                        builder: (context, state) {
                                          return InputWidget(
                                            height: 40,
                                            enabled: AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE,
                                            isNumber: true,
                                            onChange: (data) {
                                              context.read<SettingBloc>().add(ChangeRange(int.parse(meter.text)));
                                            },
                                            filled: AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE_SUB,
                                            controller: meter,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      BlocBuilder<SettingBloc, SettingState>(
                                        builder: (context, state) {
                                          return Flexible(
                                            child: Container(
                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
                                              child: GoogleMap(
                                                onMapCreated: (controller) {
                                                  mapController = controller;
                                                  context.read<SettingBloc>().add(Initial(data: mainState.enterpriseInfo));
                                                },
                                                initialCameraPosition: CameraPosition(target: state.latLng ?? const LatLng(37.541, 126.986), zoom: 15),
                                                minMaxZoomPreference: const MinMaxZoomPreference(8, 17),
                                                circles: {
                                                  if (state.latLng != null)
                                                    Circle(
                                                      circleId: const CircleId('2'),
                                                      center: state.latLng!,
                                                      radius: (state.meter ?? 1).toDouble(),
                                                      fillColor: Colors.red.withOpacity(0.3),
                                                      strokeColor: Colors.red.withOpacity(0.5),
                                                      strokeWidth: 0,
                                                    ),
                                                },
                                                markers: {
                                                  if (state.latLng != null)
                                                    Marker(
                                                      markerId: const MarkerId('1'),
                                                      position: state.latLng!,
                                                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                                                      onTap: () {},
                                                    )
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const VerticalDivider(
                                  width: 64,
                                  thickness: 1,
                                  color: gray6,
                                ),
                                BlocBuilder<SettingBloc, SettingState>(
                                  builder: (context, state) {
                                    return Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE)
                                            Row(
                                              children: [
                                                Text('업체 설정', style: textTheme(context).krSubtitle1),
                                                const Spacer(),
                                                InkWell(
                                                    onTap: () {
                                                      SettingDialog.password(context, onEdit: (value) async {
                                                        context.read<SettingBloc>().add(ChangePassword(value));
                                                      });
                                                    },
                                                    child: Text('아이디/비밀번호 변경', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff7B878D), decoration: TextDecoration.underline))),
                                              ],
                                            ),
                                          if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE_SUB)
                                            Row(
                                              children: [
                                                Text('업체 정보', style: textTheme(context).krSubtitle1),
                                              ],
                                            ),
                                          const SizedBox(height: 32),
                                          Text(AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE ? '업체 로고 설정' : '업체 로고 정보', style: textTheme(context).krBody1),
                                          const SizedBox(height: 8),
                                          BlocBuilder<SettingBloc, SettingState>(
                                            buildWhen: (prev, curr) => prev.fileBytes != curr.fileBytes,
                                            builder: (context, state) {
                                              return Wrap(
                                                runSpacing: 16,
                                                spacing: 16,
                                                children: [
                                                  SizedBox(
                                                    height: 80,
                                                    child: IntrinsicWidth(
                                                      child: DottedBorder(
                                                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                                        radius: const Radius.circular(10),
                                                        child: state.fileBytes != null
                                                            ? Image.memory(
                                                          state.fileBytes!,
                                                          height: 80,
                                                        )
                                                            : CachedNetworkImage(
                                                            imageUrl: '$resourceUrl${mainState.enterpriseInfo?.enterpriseFile?.fileName ?? ''}',
                                                            fit: BoxFit.cover,
                                                            placeholder: (context, url) {
                                                              return Container(
                                                                height: 80,
                                                              );
                                                            },
                                                            errorWidget: (context, url, error) {
                                                              return Container(
                                                                decoration: const BoxDecoration(
                                                                  color: white,
                                                                ),
                                                              );
                                                            }),
                                                      ),
                                                    ),
                                                  ),
                                                  if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE)
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        InkWell(
                                                          onTap: () async {
                                                            if (kIsWeb) {
                                                              await FilePicker.platform.pickFiles(type: FileType.custom, withReadStream: true, allowedExtensions: ['jpg', 'png', 'jpeg']).then((value) async {
                                                                if (value != null) {
                                                                  final file = value.files.first;
                                                                  await file.readStream?.first.then(
                                                                        (fileBytes) => context.read<SettingBloc>().add(PickFile(fileBytes as Uint8List, file.extension)),
                                                                  );
                                                                }
                                                              });
                                                            }
                                                          },
                                                          child: IntrinsicWidth(
                                                            child: SizedBox(
                                                              height: 40,
                                                              child: Center(
                                                                child: Container(
                                                                  alignment: Alignment.center,
                                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    color: blue1,
                                                                  ),
                                                                  child: Text('파일 업로드', style: textTheme(context).krSubtext1B.copyWith(color: white)),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Text('이미지는 jpg,png 파일만 업로드가 가능합니다.', style: textTheme(context).krSubtext2.copyWith(color: const Color(0xffAAB0B6))),
                                                      ],
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          Text('업체 이름', style: textTheme(context).krBody1),
                                          const SizedBox(height: 8),
                                          BlocSelector<MainBloc, MainState, String?>(
                                            selector: (state) => state.enterpriseInfo?.name,
                                            builder: (context, name) {
                                              return InputWidget(
                                                height: 40,
                                                filled: true,
                                                enabled: false,
                                                controller: TextEditingController(text: name ?? ''),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          Text('업체 코드', style: textTheme(context).krBody1),
                                          const SizedBox(height: 8),
                                          BlocSelector<MainBloc, MainState, String?>(
                                            selector: (state) => state.enterpriseInfo?.code,
                                            builder: (context, code) {
                                              codeController.text = code ?? '';
                                              return Row(
                                                children: [
                                                  Flexible(
                                                    child: InputWidget(
                                                      height: 40,
                                                      filled: true,
                                                      enabled: false,
                                                      controller: codeController,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          Text('관리자/제한해제 코드', style: textTheme(context).krBody1),
                                          const SizedBox(height: 8),
                                          BlocSelector<MainBloc, MainState, String?>(
                                            selector: (state) => state.enterpriseInfo?.banDisabledCode,
                                            builder: (context, code) {
                                              secretCodeController.text = code ?? '';
                                              return Row(
                                                children: [
                                                  Flexible(
                                                    child: InputWidget(
                                                      height: 40,
                                                      filled: AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE_SUB,
                                                      enabled: false,
                                                      controller: secretCodeController,
                                                    ),
                                                  ),
                                                  if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) const SizedBox(width: 16),
                                                  if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE)
                                                    InkWell(
                                                      onTap: () {
                                                        secretCodeController.text = generateRandomNumber(6);
                                                      },
                                                      child: Container(
                                                        height: 40,
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(8),
                                                          color: blue1,
                                                        ),
                                                        child: Center(
                                                          child: Text('재설정', style: textTheme(context).krSubtext1B.copyWith(color: white)),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 40),
                                          BlocSelector<SettingBloc, SettingState, (bool, bool, bool, bool, bool, bool, bool, bool)>(
                                            selector: (state) => state.functionSwitch,
                                            builder: (context, state) {
                                              return Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text('차단 실행', style: textTheme(context).krTitle1),

                                                      Text('차단 해제', style: textTheme(context).krTitle1),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 40),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(state.$1 ? 'ON 켜짐' : 'OFF 꺼짐', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                                                          CupertinoSwitch(
                                                              value: state.$1,
                                                              onChanged: (value) {
                                                                if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) {
                                                                  context.read<SettingBloc>().add(ChangeFunctionSwitch((value, state.$2, state.$3, state.$4, state.$5, state.$6, state.$7, state.$8)));
                                                                }
                                                              }),
                                                          const SizedBox(width: 16),
                                                          Text('QR코드', style: textTheme(context).krSubtitle1),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('비콘', style: textTheme(context).krSubtitle1),
                                                          const SizedBox(width: 16),
                                                          CupertinoSwitch(
                                                              value: state.$2,
                                                              onChanged: (value) {
                                                                if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) {
                                                                  context.read<SettingBloc>().add(ChangeFunctionSwitch((state.$1, value, state.$3, state.$4, state.$5, state.$6, state.$7, state.$8)));
                                                                }
                                                              }),

                                                          Text(state.$1 ? 'ON 켜짐' : 'OFF 꺼짐', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 40),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(state.$1 ? 'ON 켜짐' : 'OFF 꺼짐', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                                                          CupertinoSwitch(
                                                              value: state.$3,
                                                              onChanged: (value) {
                                                                if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) {
                                                                  context.read<SettingBloc>().add(ChangeFunctionSwitch((state.$1, state.$2, value, state.$4, state.$5, state.$6, state.$7, state.$8)));
                                                                }
                                                              }),
                                                          const SizedBox(width: 16),
                                                          Text('비콘', style: textTheme(context).krSubtitle1),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('위치기반', style: textTheme(context).krSubtitle1),
                                                          const SizedBox(width: 16),
                                                          CupertinoSwitch(
                                                              value: state.$4,
                                                              onChanged: (value) {
                                                                if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) {
                                                                  context.read<SettingBloc>().add(ChangeFunctionSwitch((state.$1, state.$2, state.$3, value, state.$5, state.$6, state.$7, state.$8)));
                                                                }
                                                              }),
                                                          Text(state.$1 ? 'ON 켜짐' : 'OFF 꺼짐', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 40),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(state.$1 ? 'ON 켜짐' : 'OFF 꺼짐', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                                                          CupertinoSwitch(
                                                              value: state.$5,
                                                              onChanged: (value) {
                                                                if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) {
                                                                  context.read<SettingBloc>().add(ChangeFunctionSwitch((state.$1, state.$2, state.$3, state.$4, value, state.$6, state.$7, state.$8)));
                                                                }
                                                              }),
                                                          const SizedBox(width: 16),
                                                          Text('NFC', style: textTheme(context).krSubtitle1),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('NFC', style: textTheme(context).krSubtitle1),
                                                          const SizedBox(width: 16),
                                                          CupertinoSwitch(
                                                              value: state.$6,
                                                              onChanged: (value) {
                                                                if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) {
                                                                  context.read<SettingBloc>().add(ChangeFunctionSwitch((state.$1, state.$2, state.$3, state.$4, state.$5, value, state.$7, state.$8)));
                                                                }
                                                              }),
                                                          Text(state.$1 ? 'ON 켜짐' : 'OFF 꺼짐', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 40),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(state.$1 ? 'ON 켜짐' : 'OFF 꺼짐', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                                                          CupertinoSwitch(
                                                              value: state.$7,
                                                              onChanged: (value) {
                                                                if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) {
                                                                  context.read<SettingBloc>().add(ChangeFunctionSwitch((state.$1, state.$2, state.$3, state.$4, state.$5, state.$6, value, state.$8)));
                                                                }
                                                              }),
                                                          const SizedBox(width: 16),
                                                          Text('업체코드', style: textTheme(context).krSubtitle1),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('관리자/제한해제 코드', style: textTheme(context).krSubtitle1),
                                                          const SizedBox(width: 16),
                                                          CupertinoSwitch(
                                                              value: state.$8,
                                                              onChanged: (value) {
                                                                if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE) {
                                                                  context.read<SettingBloc>().add(ChangeFunctionSwitch((state.$1, state.$2, state.$3, state.$4, state.$5, state.$6, state.$7, value)));
                                                                }
                                                              }),
                                                          Text(state.$1 ? 'ON 켜짐' : 'OFF 꺼짐', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 40),
                                                ],
                                              );
                                            },
                                          ),
                                          const Spacer(),
                                          const SizedBox(height: 40),
                                          if (AppConfig.to.secureModel.role == Role.ROLE_ENTERPRISE)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: IntrinsicWidth(
                                                child: BlocBuilder<SettingBloc, SettingState>(
                                                  builder: (context, state) {
                                                    return InkWell(
                                                      onTap: () {
                                                        context.read<SettingBloc>().add(Submit({
                                                          'code': codeController.text,
                                                          'banDisabledCode': secretCodeController.text,
                                                          'location': {
                                                            'address': address.text,
                                                            'latitude': context.read<SettingBloc>().state.latLng?.latitude,
                                                            'longitude': context.read<SettingBloc>().state.latLng?.longitude,
                                                            'radius': int.parse(meter.text),
                                                          },
                                                          "function": {
                                                            'qrDisable': state.functionSwitch.$1,
                                                            'beaconEnable': state.functionSwitch.$2,
                                                            'beaconDisable': state.functionSwitch.$3,
                                                            "locationEnable": state.functionSwitch.$4,
                                                            'nfcDisable': state.functionSwitch.$5,
                                                            'nfcEnable': state.functionSwitch.$6,
                                                            'manualDisable': state.functionSwitch.$7,
                                                            'manualEnable': state.functionSwitch.$8}
                                                        }, context: context));
                                                      },
                                                      child: Container(
                                                        height: 40,
                                                        width: 88,
                                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(8),
                                                          color: blue1,
                                                        ),
                                                        child: Center(
                                                          child: Text('저장', style: textTheme(context).krSubtext1B.copyWith(color: white)),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  String generateRandomNumber(int length) {
    const digits = "0123456789";
    final random = Random();

    String randomNumber = "";
    for (int i = 0; i < length; i++) {
      randomNumber += digits[random.nextInt(digits.length)];
    }

    return randomNumber;
  }
}