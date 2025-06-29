import 'package:TPASS/core/core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../settings/repository/setting_repository.dart';

class EnterpriseDialog {
  static add(BuildContext context, {Function()? onChange, Function(Uint8List, String?)? onFilePick, Function(Map<String, dynamic>)? onAdd}) {
    return dialog(context, AddEnterpriseDialog(onChange: onChange, onFilePick: onFilePick, onAdd: onAdd));
  }

  static edit(BuildContext context, {required Enterprise enterprise, Function()? onChange, Function(Uint8List, String?)? onFilePick, Function(Map<String, dynamic>)? onEdit}) {
    return dialog(context, EditEnterpriseDialog(enterprise: enterprise, onChange: onChange, onFilePick: onFilePick, onEdit: onEdit));
  }
}

class AddEnterpriseDialog extends StatefulWidget {
  const AddEnterpriseDialog({Key? key, this.onChange, this.onFilePick, this.onAdd}) : super(key: key);

  final Function()? onChange;
  final Function(Uint8List, String?)? onFilePick;
  final Function(Map<String, dynamic>)? onAdd;

  @override
  State<AddEnterpriseDialog> createState() => _AddEnterpriseDialogState();
}

class _AddEnterpriseDialogState extends State<AddEnterpriseDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController detailAddressController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  List<Document>? documents = [];
  Uint8List? fileBytes;
  LatLng? latLng;
  bool addressDone = false;

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
                    Text('업체 추가', style: textTheme(context).krSubtitle1),
                    InkWell(
                        onTap: () {
                          final dataFilled = nameController.text.isNotEmpty || codeController.text.isNotEmpty || addressController.text.isNotEmpty || fileBytes != null;
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
                    SizedBox(width: 128, child: Text('업체명', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: nameController,
                        hint: '업체명을 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('업체 코드', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        isNumber: true,
                        maxLength: 8,
                        height: 40,
                        controller: codeController,
                        hint: '업체 코드를 입력하세요. (숫자 6자리)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('업체 주소', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: addressController,
                        hint: '업체 주소를 입력 후 검색을 진행해주세요.',
                        done: addressDone,
                        onChange: (value) {
                          setState(() {
                            addressDone = false;
                          });
                        },
                        onFieldSubmitted: (value) async {
                          await SettingApi.to.getGeo(value).then((value) {
                            if ((value.documents ?? []).isNotEmpty) {
                              setState(() {
                                documents = value.documents;
                              });
                            } else {
                              showAdaptiveDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return AlertDialog.adaptive(
                                      title: const Text(
                                        '알림',
                                      ),
                                      content: Text(
                                        '일치하는 주소가 없습니다.\n다시 입력해주세요.',
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
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () async {
                        await SettingApi.to.getGeo(addressController.text).then((value) {
                          if ((value.documents ?? []).isNotEmpty) {
                            setState(() {
                              documents = value.documents;
                            });
                          }
                        });
                      },
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
                ),
                if (documents?.isNotEmpty ?? false) const SizedBox(height: 16),
                AnimatedContainer(
                    alignment: Alignment.centerLeft,
                    margin: documents?.isEmpty ?? true ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    duration: const Duration(milliseconds: 300),
                    height: documents?.isEmpty ?? true ? 0 : ((documents ?? []).take(5).length * 40),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (documents ?? []).take(5).map((document) {
                          return SizedBox(
                              height: 40,
                              child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      latLng = LatLng(double.parse(document.y ?? '37.47'), double.parse(document.x ?? '126.88'));
                                      addressController.text = document.roadAddress?.addressName ?? '';
                                      addressDone = true;
                                    });
                                  },
                                  child: Text(document.roadAddress?.addressName ?? '', style: textTheme(context).krBody1)));
                        }).toList(),
                      ),
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('아이디', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: usernameController,
                        hint: '업체 아이디를 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('비밀번호', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: pwController,
                        isPassword: true,
                        hint: '업체 비밀번호를 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('업체 이미지', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    InkWell(
                      onTap: () async {
                        if (kIsWeb) {
                          await FilePicker.platform.pickFiles(type: FileType.custom, withReadStream: true, allowedExtensions: ['jpg', 'png', 'jpeg']).then((value) async {
                            if (value != null) {
                              final file = value.files.first;
                              await file.readStream?.first.then(
                                (fileBytes) {
                                  widget.onFilePick?.call(fileBytes as Uint8List, file.extension);
                                  setState(() {
                                    this.fileBytes = fileBytes as Uint8List?;
                                  });
                                },
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: blue1,
                        ),
                        child: Center(
                          child: Text('파일 업로드', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('이미지는 jpg,png 파일만 업로드가 가능합니다.', style: textTheme(context).krSubtext2.copyWith(color: const Color(0xffAAB0B6))),
                  ],
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: 380,
                        height: 80,
                        decoration: BoxDecoration(border: Border.all(width: 1, color: const Color(0xffD2D7DD))),
                        child: fileBytes != null
                            ? Image.memory(
                                fileBytes!,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : const SvgImage(
                                'assets/icons/ic_building.svg',
                                color: Color(0xffEBECF3),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text('미리보기', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999))),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        final dataFilled = nameController.text.isNotEmpty || codeController.text.isNotEmpty || addressController.text.isNotEmpty || usernameController.text.isNotEmpty || pwController.text.isNotEmpty || fileBytes != null;
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
                        final dataFilled = latLng != null && nameController.text.isNotEmpty && codeController.text.isNotEmpty && addressController.text.isNotEmpty && usernameController.text.isNotEmpty && pwController.text.isNotEmpty && fileBytes != null;
                        if (dataFilled) {
                          widget.onAdd?.call({
                            "username": usernameController.text,
                            "password": pwController.text,
                            "nickname": "${nameController.text} 관리자",
                            "enterprise": {
                              "code": int.parse(codeController.text),
                              "name": nameController.text,
                              "location": {"address": addressController.text, "latitude": latLng?.latitude, "longitude": latLng?.longitude}
                            }
                          });
                        } else {
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                var errorText = '오류가 발생했습니다.';
                                if (nameController.text.isEmpty) {
                                  errorText = '업체명을 입력해주세요.';
                                } else if (codeController.text.isEmpty || codeController.text.length < 6) {
                                  errorText = '업체 코드를 확인해주세요.';
                                } else if (addressController.text.isEmpty) {
                                  errorText = '업체 주소를 입력해주세요.';
                                } else if (usernameController.text.isEmpty) {
                                  errorText = '아이디를 입력해주세요.';
                                } else if (pwController.text.isEmpty) {
                                  errorText = '비밀번호를 입력해주세요.';
                                } else if (fileBytes == null) {
                                  errorText = '업체 이미지를 업로드해주세요.';
                                } else if (latLng == null || !addressDone) {
                                  errorText = '업체 주소를 검색해주세요.';
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

class EditEnterpriseDialog extends StatefulWidget {
  const EditEnterpriseDialog({Key? key, this.enterprise, this.onChange, this.onFilePick, this.onEdit}) : super(key: key);

  final Enterprise? enterprise;
  final Function()? onChange;
  final Function(Uint8List, String?)? onFilePick;
  final Function(Map<String, dynamic>)? onEdit;

  @override
  State<EditEnterpriseDialog> createState() => _EditEnterpriseDialogState();
}

class _EditEnterpriseDialogState extends State<EditEnterpriseDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController detailAddressController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  List<Document>? documents = [];
  Uint8List? fileBytes;
  LatLng? latLng;
  bool addressDone = false;

  @override
  void initState() {
    nameController.text = widget.enterprise?.name ?? '';
    codeController.text = widget.enterprise?.code.toString() ?? '';
    addressController.text = widget.enterprise?.address ?? '';
    usernameController.text = widget.enterprise?.userId ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: IntrinsicHeight(
        child: Container(
          width: 800,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: white),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('업체 수정', style: textTheme(context).krSubtitle1),
                    InkWell(
                        onTap: () {
                          final dataFilled = nameController.text.isNotEmpty || codeController.text.isNotEmpty || addressController.text.isNotEmpty || fileBytes != null;
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
                    SizedBox(width: 128, child: Text('업체명', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: nameController,
                        hint: '업체명을 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('업체 코드', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
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
                    SizedBox(width: 128, child: Text('업체 주소', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: addressController,
                        hint: '업체 주소를 입력 후 검색을 진행해주세요.',
                        done: addressDone,
                        onChange: (value) {
                          setState(() {
                            addressDone = false;
                          });
                        },
                        onFieldSubmitted: (value) async {
                          await SettingApi.to.getGeo(value).then((value) {
                            if ((value.documents ?? []).isNotEmpty) {
                              setState(() {
                                documents = value.documents;
                              });
                            } else {
                              showAdaptiveDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return AlertDialog.adaptive(
                                      title: const Text(
                                        '알림',
                                      ),
                                      content: Text(
                                        '일치하는 주소가 없습니다.\n다시 입력해주세요.',
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
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () async {
                        await SettingApi.to.getGeo(addressController.text).then((value) {
                          if ((value.documents ?? []).isNotEmpty) {
                            setState(() {
                              documents = value.documents;
                            });
                          }
                        });
                      },
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
                ),
                if (documents?.isNotEmpty ?? false) const SizedBox(height: 16),
                AnimatedContainer(
                    alignment: Alignment.centerLeft,
                    margin: documents?.isEmpty ?? true ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    duration: const Duration(milliseconds: 300),
                    height: documents?.isEmpty ?? true ? 0 : ((documents ?? []).take(5).length * 40),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (documents ?? []).take(5).map((document) {
                          return SizedBox(
                              height: 40,
                              child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      latLng = LatLng(double.parse(document.y ?? '37.47'), double.parse(document.x ?? '126.88'));
                                      addressController.text = document.roadAddress?.addressName ?? '';
                                      addressDone = true;
                                    });
                                  },
                                  child: Text(document.roadAddress?.addressName ?? '', style: textTheme(context).krBody1)));
                        }).toList(),
                      ),
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('아이디', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: usernameController,
                        hint: '업체 아이디를 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('비밀번호', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: pwController,
                        isPassword: true,
                        hint: '업체 비밀번호를 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('업체 이미지', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    InkWell(
                      onTap: () async {
                        if (kIsWeb) {
                          await FilePicker.platform.pickFiles(type: FileType.custom, withReadStream: true, allowedExtensions: ['jpg', 'png', 'jpeg']).then((value) async {
                            if (value != null) {
                              final file = value.files.first;
                              await file.readStream?.first.then(
                                (fileBytes) {
                                  widget.onFilePick?.call(fileBytes as Uint8List, file.extension);
                                  setState(() {
                                    this.fileBytes = fileBytes as Uint8List?;
                                  });
                                },
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: blue1,
                        ),
                        child: Center(
                          child: Text('파일 업로드', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('이미지는 jpg,png 파일만 업로드가 가능합니다.', style: textTheme(context).krSubtext2.copyWith(color: const Color(0xffAAB0B6))),
                  ],
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: 380,
                        height: 80,
                        decoration: BoxDecoration(border: Border.all(width: 1, color: const Color(0xffD2D7DD))),
                        child: fileBytes != null
                            ? Image.memory(
                                fileBytes!,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : const SvgImage(
                                'assets/icons/ic_building.svg',
                                color: Color(0xffEBECF3),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text('미리보기', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999))),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        final dataFilled = nameController.text.isNotEmpty || codeController.text.isNotEmpty || addressController.text.isNotEmpty || usernameController.text.isNotEmpty || pwController.text.isNotEmpty || fileBytes != null;
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
                        final dataFilled = latLng != null && nameController.text.isNotEmpty && codeController.text.isNotEmpty && addressController.text.isNotEmpty && usernameController.text.isNotEmpty && pwController.text.isNotEmpty && fileBytes != null;
                        if (dataFilled) {
                          widget.onEdit?.call({
                            "username": usernameController.text,
                            "password": pwController.text,
                            "name": nameController.text,
                            "location": {"address": addressController.text, "latitude": latLng?.latitude, "longitude": latLng?.longitude},
                          });
                        } else {
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                var errorText = '오류가 발생했습니다.';
                                if (nameController.text.isEmpty) {
                                  errorText = '업체명을 입력해주세요.';
                                } else if (codeController.text.isEmpty || codeController.text.length < 8) {
                                  errorText = '업체 코드를 확인해주세요.';
                                } else if (addressController.text.isEmpty) {
                                  errorText = '업체 주소를 입력해주세요.';
                                } else if (usernameController.text.isEmpty) {
                                  errorText = '아이디를 입력해주세요.';
                                } else if (pwController.text.isEmpty) {
                                  errorText = '비밀번호를 입력해주세요.';
                                } else if (fileBytes == null) {
                                  errorText = '업체 이미지를 업로드해주세요.';
                                } else if (latLng == null || !addressDone) {
                                  errorText = '업체 주소를 검색해주세요.';
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
