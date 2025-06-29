import 'package:TPASS/core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceDialog {
  static add(BuildContext context, {Function()? onChange, Function(Uint8List, String?)? onFilePick, Function(Map<String, dynamic>)? onAdd}) {
    return dialog(context, AddDeviceDialog(onChange: onChange, onFilePick: onFilePick, onAdd: onAdd));
  }

  static edit(BuildContext context, {required Device device, Function()? onChange, Function(Uint8List, String?)? onFilePick, Function(Map<String, dynamic>)? onEdit, Function()? onDelete}) {
    return dialog(context, EditDeviceDialog(device: device, onChange: onChange, onFilePick: onFilePick, onEdit: onEdit, onDelete: onDelete));
  }
}

class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({Key? key, this.onChange, this.onFilePick, this.onAdd}) : super(key: key);

  final Function()? onChange;
  final Function(Uint8List, String?)? onFilePick;
  final Function(Map<String, dynamic>)? onAdd;

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController deviceController = TextEditingController();
  final TextEditingController qrController = TextEditingController();

  AbleType ableType = AbleType.DISABLE;
  DeviceType deviceType = DeviceType.NFC;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: IntrinsicHeight(
        child: Container(
          width: 800,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('기기 추가', style: textTheme(context).krSubtitle1),
                    InkWell(
                        onTap: () {
                          final dataFilled = deviceController.text.isNotEmpty || codeController.text.isNotEmpty;
                          if (dataFilled) {
                            showAdaptiveDialog(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog.adaptive(
                                    title: const Text(
                                      '알림',
                                    ),
                                    content: Text(
                                      '작성중인 내용이 있습니다. \n정말로 취소하시겠습니까?',
                                      style: textTheme(context).krBody1,
                                    ),
                                    actions: <Widget>[
                                      adaptiveAction(
                                        context: context,
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        isCancel: true,
                                        child: const Text('취소'),
                                      ),
                                      adaptiveAction(
                                        context: context,
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  );
                                });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('등록 업체 코드', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        isNumber: true,
                        maxLength: 8,
                        height: 40,
                        controller: codeController,
                        hint: '업체 코드를 입력하세요. (숫자 8자리)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('구분', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: DropdownMenuWidget<AbleType>(
                        dropdownList: const [AbleType.DISABLE, AbleType.ENABLE],
                        onChanged: (value) {
                          setState(() {
                            ableType = value ?? AbleType.DISABLE;
                          });
                        },
                        value: ableType,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('기기 종류', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: DropdownMenuWidget<DeviceType>(
                        dropdownList: const [DeviceType.NFC, DeviceType.BEACON, DeviceType.QR],
                        onChanged: (value) {
                          deviceType = value ?? DeviceType.NFC;
                          logger.d(value);
                          logger.d(deviceType);
                        },
                        value: deviceType,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('일련번호', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: deviceController,
                        hint: '기기 일련번호를 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        final dataFilled = codeController.text.isNotEmpty || deviceController.text.isNotEmpty;
                        if (dataFilled) {
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog.adaptive(
                                  title: const Text(
                                    '알림',
                                  ),
                                  content: Text(
                                    '작성중인 내용이 있습니다. \n정말로 취소하시겠습니까?',
                                    style: textTheme(context).krBody1,
                                  ),
                                  actions: <Widget>[
                                    adaptiveAction(
                                      context: context,
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      isCancel: true,
                                      child: const Text('취소'),
                                    ),
                                    adaptiveAction(
                                      context: context,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('확인'),
                                    ),
                                  ],
                                );
                              });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 88,
                        decoration: BoxDecoration(
                          color: black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: Text('취소', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        final dataFilled = codeController.text.isNotEmpty && deviceController.text.isNotEmpty;
                        if (dataFilled) {
                          widget.onAdd?.call({"id": deviceController.text, "type": ableType.name, "enterpriseCode": codeController.text, "deviceType": deviceType.name});
                        } else {
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                var errorText = '오류가 발생했습니다.';
                                if (codeController.text.isEmpty || codeController.text.length < 6) {
                                  errorText = '업체 코드를 확인해주세요.';
                                } else if (deviceController.text.isEmpty) {
                                  errorText = '기기 일련번호를 입력해주세요.';
                                }
                                return AlertDialog.adaptive(
                                  title: const Text(
                                    '알림',
                                  ),
                                  content: Text(
                                    errorText,
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
                      child: Container(
                        width: 88,
                        decoration: BoxDecoration(
                          color: blue1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: Text('저장', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold))),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditDeviceDialog extends StatefulWidget {
  const EditDeviceDialog({Key? key, required this.device, this.onChange, this.onFilePick, this.onEdit, this.onDelete}) : super(key: key);

  final Device device;
  final Function()? onChange;
  final Function(Uint8List, String?)? onFilePick;
  final Function(Map<String, dynamic>)? onEdit;
  final Function()? onDelete;

  @override
  State<EditDeviceDialog> createState() => _EditDeviceDialogState();
}

class _EditDeviceDialogState extends State<EditDeviceDialog> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController deviceController = TextEditingController();

  AbleType ableType = AbleType.DISABLE;
  DeviceType deviceType = DeviceType.NFC;
  DeviceActive deviceActive = DeviceActive.ACTIVE;

  @override
  void initState() {
    codeController.text = widget.device.enterprise?.code ?? '';
    deviceController.text = widget.device.tagId ?? '';
    ableType = widget.device.type == 'ENABLE' ? AbleType.ENABLE : AbleType.DISABLE;
    deviceType = widget.device.deviceType == 'NFC' ? DeviceType.NFC : DeviceType.BEACON;
    deviceActive = widget.device.deviceActive == true ? DeviceActive.ACTIVE : DeviceActive.INACTIVE;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: IntrinsicHeight(
        child: Container(
          width: 800,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('기기 추가', style: textTheme(context).krSubtitle1),
                    InkWell(
                        onTap: () {
                          final dataFilled = deviceController.text.isNotEmpty || codeController.text.isNotEmpty;
                          if (dataFilled) {
                            showAdaptiveDialog(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog.adaptive(
                                    title: const Text(
                                      '알림',
                                    ),
                                    content: Text(
                                      '작성중인 내용이 있습니다. \n정말로 취소하시겠습니까?',
                                      style: textTheme(context).krBody1,
                                    ),
                                    actions: <Widget>[
                                      adaptiveAction(
                                        context: context,
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        isCancel: true,
                                        child: const Text('취소'),
                                      ),
                                      adaptiveAction(
                                        context: context,
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  );
                                });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('등록 업체 코드', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        enabled: false,
                        isNumber: true,
                        maxLength: 8,
                        height: 40,
                        controller: codeController,
                        hint: '업체 코드를 입력하세요. (숫자 8자리)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('구분', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: DropdownMenuWidget<AbleType>(
                        dropdownList: const [AbleType.DISABLE, AbleType.ENABLE],
                        onChanged: (value) {
                          setState(() {
                            ableType = value ?? AbleType.DISABLE;
                          });
                        },
                        value: ableType,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('기기 종류', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: DropdownMenuWidget<DeviceType>(
                        dropdownList: const [DeviceType.NFC, DeviceType.BEACON, DeviceType.QR],
                        onChanged: (value) {
                          deviceType = value ?? DeviceType.NFC;
                        },
                        value: deviceType,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    SizedBox(width: 128, child: Text('일련번호', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: deviceController,
                        hint: '기기 일련번호를 입력하세요.',
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 16),
                // Row(
                //   children: [
                //     SizedBox(width: 128, child: Text('기기 활성화', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                //     Expanded(
                //       child: DropdownMenuWidget<DeviceActive>(
                //         dropdownList: [DeviceActive.ACTIVE, DeviceActive.INACTIVE],
                //         onChanged: (value) {
                //           deviceActive = value ?? DeviceActive.ACTIVE;
                //         },
                //         value: deviceActive,
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        showAdaptiveDialog(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog.adaptive(
                                title: const Text(
                                  '알림',
                                ),
                                content: Text(
                                  '기기를 삭제하시겠습니까?',
                                  style: textTheme(context).krBody1,
                                ),
                                actions: <Widget>[
                                  adaptiveAction(
                                    context: context,
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    isCancel: true,
                                    child: const Text('취소'),
                                  ),
                                  adaptiveAction(
                                    context: context,
                                    onPressed: () {
                                      widget.onDelete?.call();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('확인'),
                                  ),
                                ],
                              );
                            });
                      },
                      child: Container(
                        width: 88,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: Text('삭제', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        final dataFilled = codeController.text.isNotEmpty || deviceController.text.isNotEmpty;
                        if (dataFilled) {
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog.adaptive(
                                  title: const Text(
                                    '알림',
                                  ),
                                  content: Text(
                                    '작성중인 내용이 있습니다. \n정말로 취소하시겠습니까?',
                                    style: textTheme(context).krBody1,
                                  ),
                                  actions: <Widget>[
                                    adaptiveAction(
                                      context: context,
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      isCancel: true,
                                      child: const Text('취소'),
                                    ),
                                    adaptiveAction(
                                      context: context,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('확인'),
                                    ),
                                  ],
                                );
                              });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 88,
                        decoration: BoxDecoration(
                          color: black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: Text('취소', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        final dataFilled = codeController.text.isNotEmpty && deviceController.text.isNotEmpty;
                        if (dataFilled) {
                          widget.onEdit?.call({"changeId": deviceController.text, "type": ableType.name, "enterpriseCode": codeController.text, "deviceType": deviceType.name, "deviceActive" : deviceActive.name == 'ACTIVE' ? true : false});
                        } else {
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                var errorText = '오류가 발생했습니다.';
                                if (codeController.text.isEmpty || codeController.text.length < 8) {
                                  errorText = '업체 코드를 확인해주세요.';
                                } else if (deviceController.text.isEmpty) {
                                  errorText = '기기 일련번호를 입력해주세요.';
                                }
                                return AlertDialog.adaptive(
                                  title: const Text(
                                    '알림',
                                  ),
                                  content: Text(
                                    errorText,
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
                      child: Container(
                        width: 88,
                        decoration: BoxDecoration(
                          color: blue1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: Text('저장', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold))),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
