import 'package:GateON/core/core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../settings/repository/setting_repository.dart';

/// 업체 주소 검색 안내 문구. 도로명주소만 사용하며, 미입력·지번검색·검색결과 없음에 공통 사용한다.
const String _addressGuideMessage = '상세 주소를 입력해주세요.\n도로명 예시 : 서울 금천구 가산디지털1로 128 에스티엑스브이타워\n지번 예시 : 서울 금천구 가산동 371-37';

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

  void _showAlert(String message) {
    showAdaptiveDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog.adaptive(
            title: const Text('알림'),
            content: Text(message, style: textTheme(context).krBody1),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        maxLength: 6,
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
                        hint: '상세 주소를 입력해주세요.',
                        done: addressDone,
                        onChange: (value) {
                          setState(() {
                            addressDone = false;
                          });
                        },
                        onFieldSubmitted: (value) async {
                          // 주소 미입력 시 검색 차단
                          if (value.trim().isEmpty) {
                            _showAlert(_addressGuideMessage);
                            return;
                          }
                          await SettingApi.to.getGeo(value).then((value) {
                            // 도로명주소가 있는 결과만 사용 (지번만 있는 결과는 제외)
                            final roadDocuments = (value.documents ?? []).where((d) => (d.roadAddress?.addressName ?? '').isNotEmpty).toList();
                            if (roadDocuments.isNotEmpty) {
                              setState(() {
                                documents = roadDocuments;
                              });
                            } else {
                              // 도로명주소 결과가 없으면(지번 검색 등) 안내창 표시
                              _showAlert(_addressGuideMessage);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () async {
                        // 주소 미입력 시 검색 차단
                        if (addressController.text.trim().isEmpty) {
                          _showAlert(_addressGuideMessage);
                          return;
                        }
                        await SettingApi.to.getGeo(addressController.text).then((value) {
                          // 도로명주소가 있는 결과만 사용 (지번만 있는 결과는 제외)
                          final roadDocuments = (value.documents ?? []).where((d) => (d.roadAddress?.addressName ?? '').isNotEmpty).toList();
                          if (roadDocuments.isNotEmpty) {
                            setState(() {
                              documents = roadDocuments;
                            });
                          } else {
                            // 도로명주소 결과가 없으면(지번 검색 등) 안내창 표시
                            _showAlert(_addressGuideMessage);
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
                              // 업체 이미지 용량 제한 (10MB). 값 변경 시 이 상수만 수정.
                              const int maxLogoBytes = 10 * 1024 * 1024;
                              if (file.size > maxLogoBytes) {
                                if (context.mounted) {
                                  showAdaptiveDialog(
                                    context: context,
                                    builder: (context) => AlertDialog.adaptive(
                                      title: const Text('알림'),
                                      content: const Text('이미지는 10MB 이하만 업로드할 수 있습니다.'),
                                      actions: [
                                        adaptiveAction(
                                          context: context,
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return;
                              }
                              // readStream 전체를 안전하게 수집(빈 스트림/다중 청크 대응).
                              // .first 는 빈 파일에서 'Bad state: No element' 예외가 발생하고 첫 청크만 읽는 문제가 있다.
                              Uint8List? imageBytes;
                              try {
                                final chunks = await file.readStream?.toList() ?? [];
                                imageBytes = Uint8List.fromList(chunks.expand((c) => c).toList());
                              } catch (_) {
                                imageBytes = null;
                              }
                              // 손상/비이미지 파일 검증
                              final imageError = await validateImageBytes(imageBytes);
                              if (imageError != null) {
                                if (context.mounted) _showAlert(imageError);
                                return;
                              }
                              widget.onFilePick?.call(imageBytes!, file.extension);
                              setState(() {
                                fileBytes = imageBytes;
                              });
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
                    Text('이미지는 jpg,png 파일만 업로드가 가능합니다. (최대 10MB)', style: textTheme(context).krSubtext2.copyWith(color: const Color(0xffAAB0B6))),
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
                        // 화면 필드 순서대로 검증: 업체명 → 업체 코드 → 업체 주소 → 아이디 → 비밀번호 → 업체 이미지
                        if (nameController.text.isEmpty) {
                          _showAlert('업체명을 입력해주세요.');
                          return;
                        }
                        // 업체명 검증 (한글·영문·숫자만, 2~24자)
                        final namePolicyError = validateEnterpriseNamePolicy(nameController.text);
                        if (namePolicyError != null) {
                          _showAlert(namePolicyError);
                          return;
                        }
                        // 업체 코드 검증 (숫자 6자리 고정)
                        if (codeController.text.length != 6) {
                          _showAlert('업체 코드를 확인해주세요.\n(숫자 6자리)');
                          return;
                        }
                        if (addressController.text.isEmpty) {
                          _showAlert('업체 주소를 입력해주세요.');
                          return;
                        }
                        if (latLng == null || !addressDone) {
                          _showAlert('업체 주소를 검색해주세요.');
                          return;
                        }
                        if (usernameController.text.isEmpty) {
                          _showAlert('아이디를 입력해주세요.');
                          return;
                        }
                        // 아이디 검증 (영문·숫자만, 5~12자)
                        final idPolicyError = validateIdPolicy(usernameController.text);
                        if (idPolicyError != null) {
                          _showAlert(idPolicyError);
                          return;
                        }
                        if (pwController.text.isEmpty) {
                          _showAlert('비밀번호를 입력해주세요.');
                          return;
                        }
                        // 비밀번호 복잡도 검증 (9~32자, 영문 대문자·숫자·특수문자 각 1자 이상)
                        final pwPolicyError = validatePasswordPolicy(pwController.text);
                        if (pwPolicyError != null) {
                          _showAlert(pwPolicyError);
                          return;
                        }
                        if (fileBytes == null) {
                          _showAlert('업체 이미지를 업로드해주세요.');
                          return;
                        }
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

  void _showAlert(String message) {
    showAdaptiveDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog.adaptive(
            title: const Text('알림'),
            content: Text(message, style: textTheme(context).krBody1),
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
      child: Container(
        width: 800,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: white),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        maxLength: 6,
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
                        hint: '상세 주소를 입력해주세요.',
                        done: addressDone,
                        onChange: (value) {
                          setState(() {
                            addressDone = false;
                          });
                        },
                        onFieldSubmitted: (value) async {
                          // 주소 미입력 시 검색 차단
                          if (value.trim().isEmpty) {
                            _showAlert(_addressGuideMessage);
                            return;
                          }
                          await SettingApi.to.getGeo(value).then((value) {
                            // 도로명주소가 있는 결과만 사용 (지번만 있는 결과는 제외)
                            final roadDocuments = (value.documents ?? []).where((d) => (d.roadAddress?.addressName ?? '').isNotEmpty).toList();
                            if (roadDocuments.isNotEmpty) {
                              setState(() {
                                documents = roadDocuments;
                              });
                            } else {
                              // 도로명주소 결과가 없으면(지번 검색 등) 안내창 표시
                              _showAlert(_addressGuideMessage);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () async {
                        // 주소 미입력 시 검색 차단
                        if (addressController.text.trim().isEmpty) {
                          _showAlert(_addressGuideMessage);
                          return;
                        }
                        await SettingApi.to.getGeo(addressController.text).then((value) {
                          // 도로명주소가 있는 결과만 사용 (지번만 있는 결과는 제외)
                          final roadDocuments = (value.documents ?? []).where((d) => (d.roadAddress?.addressName ?? '').isNotEmpty).toList();
                          if (roadDocuments.isNotEmpty) {
                            setState(() {
                              documents = roadDocuments;
                            });
                          } else {
                            // 도로명주소 결과가 없으면(지번 검색 등) 안내창 표시
                            _showAlert(_addressGuideMessage);
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
                              // 업체 이미지 용량 제한 (10MB). 값 변경 시 이 상수만 수정.
                              const int maxLogoBytes = 10 * 1024 * 1024;
                              if (file.size > maxLogoBytes) {
                                if (context.mounted) {
                                  showAdaptiveDialog(
                                    context: context,
                                    builder: (context) => AlertDialog.adaptive(
                                      title: const Text('알림'),
                                      content: const Text('이미지는 10MB 이하만 업로드할 수 있습니다.'),
                                      actions: [
                                        adaptiveAction(
                                          context: context,
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return;
                              }
                              // readStream 전체를 안전하게 수집(빈 스트림/다중 청크 대응).
                              // .first 는 빈 파일에서 'Bad state: No element' 예외가 발생하고 첫 청크만 읽는 문제가 있다.
                              Uint8List? imageBytes;
                              try {
                                final chunks = await file.readStream?.toList() ?? [];
                                imageBytes = Uint8List.fromList(chunks.expand((c) => c).toList());
                              } catch (_) {
                                imageBytes = null;
                              }
                              // 손상/비이미지 파일 검증
                              final imageError = await validateImageBytes(imageBytes);
                              if (imageError != null) {
                                if (context.mounted) _showAlert(imageError);
                                return;
                              }
                              widget.onFilePick?.call(imageBytes!, file.extension);
                              setState(() {
                                fileBytes = imageBytes;
                              });
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
                    Text('이미지는 jpg,png 파일만 업로드가 가능합니다. (최대 10MB)', style: textTheme(context).krSubtext2.copyWith(color: const Color(0xffAAB0B6))),
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
                        // 화면 필드 순서대로 검증: 업체명 → 업체 주소 → 아이디 → 비밀번호 → 업체 이미지
                        // (업체 코드는 수정 불가 필드라 검증하지 않는다.)
                        if (nameController.text.isEmpty) {
                          _showAlert('업체명을 입력해주세요.');
                          return;
                        }
                        // 업체명 검증 (한글·영문·숫자만, 2~24자)
                        final namePolicyError = validateEnterpriseNamePolicy(nameController.text);
                        if (namePolicyError != null) {
                          _showAlert(namePolicyError);
                          return;
                        }
                        if (addressController.text.isEmpty) {
                          _showAlert('업체 주소를 입력해주세요.');
                          return;
                        }
                        if (latLng == null || !addressDone) {
                          _showAlert('업체 주소를 검색해주세요.');
                          return;
                        }
                        if (usernameController.text.isEmpty) {
                          _showAlert('아이디를 입력해주세요.');
                          return;
                        }
                        // 아이디 검증 (영문·숫자만, 5~12자)
                        final idPolicyError = validateIdPolicy(usernameController.text);
                        if (idPolicyError != null) {
                          _showAlert(idPolicyError);
                          return;
                        }
                        if (pwController.text.isEmpty) {
                          _showAlert('비밀번호를 입력해주세요.');
                          return;
                        }
                        // 비밀번호 복잡도 검증 (9~32자, 영문 대문자·숫자·특수문자 각 1자 이상)
                        final pwPolicyError = validatePasswordPolicy(pwController.text);
                        if (pwPolicyError != null) {
                          _showAlert(pwPolicyError);
                          return;
                        }
                        if (fileBytes == null) {
                          _showAlert('업체 이미지를 업로드해주세요.');
                          return;
                        }
                        widget.onEdit?.call({
                          "username": usernameController.text,
                          "password": pwController.text,
                          "name": nameController.text,
                          "location": {"address": addressController.text, "latitude": latLng?.latitude, "longitude": latLng?.longitude},
                        });
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
