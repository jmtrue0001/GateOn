import 'package:TPASS/core/core.dart';
import 'package:flutter/material.dart';

class SubAdminDialog {
  static add(BuildContext context, {Function(Map<String, dynamic>)? onAdd}) {
    return dialog(context, AddSubAdminDialog(onAdd: onAdd));
  }

  static edit(BuildContext context, {SubAdmin? subAdmin, Function(Map<String, dynamic>)? onEdit}) {
    return dialog(context, EditSubAdminDialog(subAdmin: subAdmin, onEdit: onEdit));
  }
}

class AddSubAdminDialog extends StatefulWidget {
  const AddSubAdminDialog({Key? key, this.onAdd}) : super(key: key);

  final Function(Map<String, dynamic>)? onAdd;

  @override
  State<AddSubAdminDialog> createState() => _AddSubAdminDialogState();
}

class _AddSubAdminDialogState extends State<AddSubAdminDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController checkController = TextEditingController();

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
                    Text('담당 관리자 추가', style: textTheme(context).krSubtitle1),
                    InkWell(
                        onTap: () {
                          final dataFilled = nameController.text.isNotEmpty || idController.text.isNotEmpty || pwController.text.isNotEmpty;
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
                    SizedBox(width: 128, child: Text('사용자 이름', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: nameController,
                        hint: '사용자 이름을 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('아이디', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: idController,
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
                    SizedBox(width: 128, child: Text('비밀번호 확인', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: checkController,
                        isPassword: true,
                        hint: '업체 비밀번호를 다시 입력하세요.',
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
                        final dataFilled = nameController.text.isNotEmpty || idController.text.isNotEmpty || pwController.text.isNotEmpty;
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
                        final dataFilled = nameController.text.isNotEmpty && idController.text.isNotEmpty && pwController.text.isNotEmpty;
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
                          widget.onAdd?.call({
                            "username": idController.text,
                            "password": pwController.text,
                            "nickname": nameController.text,
                          });
                        } else {
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                var errorText = '오류가 발생했습니다.';
                                if (nameController.text.isEmpty) {
                                  errorText = '사용자 이름을 입력해주세요.';
                                } else if (idController.text.isEmpty) {
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

class EditSubAdminDialog extends StatefulWidget {
  const EditSubAdminDialog({Key? key, this.onEdit, this.subAdmin}) : super(key: key);

  final Function(Map<String, dynamic>)? onEdit;
  final SubAdmin? subAdmin;

  @override
  State<EditSubAdminDialog> createState() => _EditSubAdminDialogState();
}

class _EditSubAdminDialogState extends State<EditSubAdminDialog> {
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController idController = TextEditingController();
  late final TextEditingController pwController = TextEditingController();

  @override
  void initState() {
    nameController.text = widget.subAdmin?.nickname ?? '';
    idController.text = widget.subAdmin?.username ?? '';

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
                    Text('담당 관리자 정보변경', style: textTheme(context).krSubtitle1),
                    InkWell(
                        onTap: () {
                          final dataFilled = nameController.text.isNotEmpty || idController.text.isNotEmpty || pwController.text.isNotEmpty;
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
                    SizedBox(width: 128, child: Text('사용자 이름', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: nameController,
                        hint: '사용자 이름을 입력하세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 128, child: Text('아이디', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)))),
                    Expanded(
                      child: InputWidget(
                        width: double.infinity,
                        height: 40,
                        controller: idController,
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
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        final dataFilled = nameController.text.isNotEmpty || idController.text.isNotEmpty || pwController.text.isNotEmpty;
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
                        final dataFilled = nameController.text.isNotEmpty && idController.text.isNotEmpty && pwController.text.isNotEmpty;
                        if (dataFilled) {
                          widget.onEdit?.call({
                            "username": idController.text,
                            "password": pwController.text,
                            "nickname": nameController.text,
                          });
                        } else {
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                var errorText = '오류가 발생했습니다.';
                                if (nameController.text.isEmpty) {
                                  errorText = '사용자 이름을 입력해주세요.';
                                } else if (idController.text.isEmpty) {
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
