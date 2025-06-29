import 'package:TPASS/core/core.dart';
import 'package:TPASS/core/widget/input_widget.dart';
import 'package:flutter/material.dart';

class SettingDialog {
  static password(BuildContext context, {Function(Map<String, dynamic>)? onEdit}) {
    return dialog(context, EditPasswordDialog(onEdit: onEdit));
  }
}

class EditPasswordDialog extends StatefulWidget {
  const EditPasswordDialog({Key? key, this.onChange, this.onEdit}) : super(key: key);

  final Function()? onChange;
  final Function(Map<String, dynamic>)? onEdit;

  @override
  State<EditPasswordDialog> createState() => _EditPasswordDialogState();
}

class _EditPasswordDialogState extends State<EditPasswordDialog> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController checkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: IntrinsicHeight(
        child: Container(
          width: 540,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('아이디/비밀번호 변경', style: textTheme(context).krSubtitle1),
                  const SizedBox(height: 40),
                  InputWidget(
                    label: '새 아이디 입력',
                    width: double.infinity,
                    height: 40,
                    controller: idController,
                    isId: true,
                    hint: '새로운 아이디를 입력해주세요.',
                  ),
                  const SizedBox(height: 16),
                  InputWidget(
                    label: '새 비밀번호 입력',
                    width: double.infinity,
                    height: 40,
                    isPassword: true,
                    controller: pwController,
                    hint: '새로운 비밀번호를 입력해주세요.',
                  ),
                  const SizedBox(height: 16),
                  InputWidget(
                    label: '새 비밀번호 확인',
                    width: double.infinity,
                    height: 40,
                    isPassword: true,
                    controller: checkController,
                    hint: '새로운 비밀번호를 한번 더 입력해주세요.',
                  ),
                  const SizedBox(height: 72),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          final dataFilled = pwController.text.isNotEmpty;
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
                          final dataFilled = pwController.text.isNotEmpty && idController.text.isNotEmpty;
                          if (pwController.text.isNotEmpty && pwController.text != checkController.text) {
                            showAdaptiveDialog(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog.adaptive(
                                    title: const Text(
                                      '알림',
                                    ),
                                    content: Text(
                                      '비밀번호가 일치하지 않습니다.',
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
                            return;
                          }
                          if (dataFilled) {
                            widget.onEdit?.call({'username': idController.text, "password": pwController.text});
                          } else {
                            showAdaptiveDialog(
                                context: context,
                                builder: (ctx) {
                                  var errorText = '오류가 발생했습니다.';
                                  if (idController.text.isEmpty) {
                                    errorText = '아이디를 입력해주세요.';
                                  } else if (pwController.text.isEmpty) {
                                    errorText = '비밀번호를 입력해주세요.';
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
                      ),
                    ],
                  )
                ],
              )),
        ),
      ),
    );
  }
}
