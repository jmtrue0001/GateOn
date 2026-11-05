import 'package:GateON/core/core.dart';
import 'package:flutter/material.dart';

/// 관리자 계정(아이디/비밀번호) 변경 다이얼로그.
/// 현재 비밀번호로 본인 확인 후 새 아이디/새 비밀번호를 함께 변경한다.
/// onEdit 으로 {currentPassword, newUsername, newPassword} 를 전달한다.
class AccountDialog {
  /// [forced] true 이면 최초 로그인 강제 변경 모드: 취소/닫기 불가.
  static edit(BuildContext context, {Function(Map<String, dynamic>)? onEdit, bool forced = false}) {
    return dialog(context, EditAccountDialog(onEdit: onEdit, forced: forced));
  }
}

class EditAccountDialog extends StatefulWidget {
  const EditAccountDialog({Key? key, this.onEdit, this.forced = false}) : super(key: key);

  final Function(Map<String, dynamic>)? onEdit;

  /// 최초 로그인 강제 변경 모드. 취소 버튼·닫기(X)·바깥 클릭·뒤로가기로 닫을 수 없다.
  final bool forced;

  @override
  State<EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<EditAccountDialog> {
  final TextEditingController currentPwController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController checkController = TextEditingController();

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

  bool get _dataFilled =>
      currentPwController.text.isNotEmpty ||
      idController.text.isNotEmpty ||
      pwController.text.isNotEmpty ||
      checkController.text.isNotEmpty;

  void _onCancel() {
    if (_dataFilled) {
      showAdaptiveDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog.adaptive(
              title: const Text('알림'),
              content: Text('작성중인 내용이 있습니다. \n정말로 취소하시겠습니까?', style: textTheme(context).krBody1),
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
  }

  void _onSave() {
    // 검증 순서: (현재 비밀번호) → 새 아이디 → 새 비밀번호 → 비밀번호 확인
    // 최초 로그인 강제 변경(forced)에서는 현재 비밀번호를 입력받지 않는다.
    if (!widget.forced && currentPwController.text.isEmpty) {
      _showAlert('현재 비밀번호를 입력해주세요.');
      return;
    }
    if (idController.text.isEmpty) {
      _showAlert('새 아이디를 입력해주세요.');
      return;
    }
    // 아이디 검증 (영문·숫자만, 5~12자)
    final idPolicyError = validateIdPolicy(idController.text);
    if (idPolicyError != null) {
      _showAlert(idPolicyError);
      return;
    }
    if (pwController.text.isEmpty) {
      _showAlert('새 비밀번호를 입력해주세요.');
      return;
    }
    if (pwController.text != checkController.text) {
      _showAlert('새 비밀번호가 일치하지 않습니다.');
      return;
    }
    // 비밀번호 복잡도 검증 (9~32자, 영문 대문자·숫자·특수문자 각 1자 이상)
    final pwPolicyError = validatePasswordPolicy(pwController.text);
    if (pwPolicyError != null) {
      _showAlert(pwPolicyError);
      return;
    }
    widget.onEdit?.call({
      // 최초 로그인 강제 변경 시에는 currentPassword 를 보내지 않는다.
      if (!widget.forced) 'currentPassword': currentPwController.text,
      'newUsername': idController.text,
      'newPassword': pwController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 강제 모드에서는 뒤로가기/ESC로 닫지 못하게 막는다.
      canPop: !widget.forced,
      child: Dialog(
      child: Container(
        width: 540,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('아이디/비밀번호 변경', style: textTheme(context).krSubtitle1),
                    // 강제 모드에서는 닫기(X) 버튼을 숨긴다.
                    if (!widget.forced) InkWell(onTap: _onCancel, child: const Icon(Icons.close)),
                  ],
                ),
                if (widget.forced) ...[
                  const SizedBox(height: 16),
                  Text('보안을 위해 최초 로그인 시 아이디와 비밀번호를 변경해야 합니다.', style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D))),
                ],
                const SizedBox(height: 40),
                // 최초 로그인 강제 변경 시에는 현재 비밀번호 입력을 받지 않는다.
                if (!widget.forced) ...[
                  InputWidget(
                    label: '현재 비밀번호 입력',
                    width: double.infinity,
                    height: 40,
                    isPassword: true,
                    controller: currentPwController,
                    hint: '현재 비밀번호를 입력해주세요.',
                  ),
                  const SizedBox(height: 16),
                ],
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
                    // 강제 모드에서는 취소 버튼을 숨긴다.
                    if (!widget.forced) ...[
                      InkWell(
                        onTap: _onCancel,
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
                    ],
                    InkWell(
                      onTap: _onSave,
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
            ),
          ),
        ),
      ),
      ),
    );
  }
}
