import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/core.dart';
import '../bloc/splash_bloc.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc()..add(const Initial()),
      child: BlocConsumer<SplashBloc, SplashState>(listener: (context, state) {
        if (state.status == CommonStatus.success) {
          logger.d(state.route);
          Future.delayed(const Duration(milliseconds: 3000), () {
            context.go('${state.route}');
          });
        }else if (state.status == CommonStatus.failure){
          showAdaptiveDialog(
              context: context,
              builder: (context) {
                return AlertDialog.adaptive(
                  title: const Text(
                    '알림',
                  ),
                  content: Text(
                    '최신버전을 스토어에서 업데이트 해주세요',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () async {
                        await launchUrlString(
                            state.errorMessage!,
                            mode: LaunchMode.externalApplication
                        );
                      },
                      child: const Text('확인'),
                    ),
                  ],
                );
              });
        }
      }, builder: (context, state) {
        return Scaffold(
          backgroundColor: colorTheme(context).splashColor,
          body: Center(
            child: AnimatedSwitcher(
              transitionBuilder: (Widget child, Animation<double> animation) {
                const begin = 0.0;
                const end = 1.0;
                final tween = Tween(begin: begin, end: end);
                return FadeTransition(opacity: animation.drive(tween.chain(CurveTween(curve: Curves.easeIn))), child: child);
              },
              duration: const Duration(milliseconds: 500),
              child: switch (state.status) {

                CommonStatus.success || CommonStatus.failure || CommonStatus.loading => const SvgImage("assets/images/logo_image.svg", height: 180, color: white),
                CommonStatus.initial || CommonStatus.error => Container(),
              },
            ),
          ),
        );
      }),
    );
  }
}
