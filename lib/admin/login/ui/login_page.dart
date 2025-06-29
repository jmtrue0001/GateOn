import 'package:TPASS/admin/login/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../core/widget/input_widget.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController idController = TextEditingController();
    final TextEditingController pwController = TextEditingController();

    return BlocProvider(
      create: (context) => LoginBloc(),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          switch (state.status) {
            case CommonStatus.success:
              context.pushReplacement('/');
              break;
            case CommonStatus.failure:
              showAdaptiveDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog.adaptive(
                      title: const Text(
                        '알림',
                      ),
                      content: Text(
                        state.errorMessage ?? '',
                      ),
                      actions: <Widget>[
                        adaptiveAction(
                          context: context,
                          onPressed: () => Navigator.pop(context, '확인'),
                          child: const Text('확인'),
                        ),
                      ],
                    );
                  });

              break;
            default:
              break;
          }
        },
        child: Scaffold(
          backgroundColor: blue1,
          body: SingleChildScrollView(
            child: BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 144, horizontal: 80),
                    width: 1128,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), color: white),
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(alignment: Alignment.centerLeft, child: Text("관리자 로그인", style: textTheme(context).krTitle2)),
                          const SizedBox(height: 32),
                          const SvgImage('assets/images/logo_image.svg', height: 160),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 160),
                            child: InputWidget(
                              controller: idController,
                              label: '아이디',
                              isId: true,
                              enabled: true,
                              hint: '아이디를 입력해주세요.',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 160),
                            child: InputWidget(
                              controller: pwController,
                              hint: '비밀번호를 입력해주세요.',
                              label: '비밀번호',
                              isPassword: true,
                              onFieldSubmitted: (value) {
                                if (idController.text.isEmpty || pwController.text.isEmpty) return;
                                context.read<LoginBloc>().add(Login(idController.text, pwController.text));
                              },
                            ),
                          ),
                          const SizedBox(height: 64),
                          BlocBuilder<LoginBloc, LoginState>(
                            builder: (context, state) {
                              return InkWell(
                                onTap: () {
                                  context.read<LoginBloc>().add(Login(idController.text, pwController.text));
                                  // context.pushNamed('main');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 160),
                                  child: Container(
                                    decoration: BoxDecoration(color: blue1, borderRadius: BorderRadius.circular(14)),
                                    height: 72,
                                    child: Center(
                                        child: Text(
                                      '로그인',
                                      style: textTheme(context).krTitle2.copyWith(color: white),
                                    )),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 100),
                          Text('CopyrightⓒJMTRUE. All rights reserved.', style: textTheme(context).krSubtext2.copyWith(color: gray3)),
                          const SizedBox(height: 32)
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
