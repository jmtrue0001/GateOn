import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/core.dart';
import '../bloc/splash_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with WidgetsBindingObserver {
  late SplashBloc _bloc;
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = SplashBloc()..add(const Initial());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_wasPaused) {
          _wasPaused = false;
          if (_fromPermissionSettings) {
            _returningFromSettings = true;
            _bloc.add(const Initial());
          }
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _wasPaused = true;
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  bool _isLoadingDialogShowing = false;
  bool _returningFromSettings = false;
  bool _fromPermissionSettings = false;

  void _dismissLoadingDialog(BuildContext context) {
    if (_isLoadingDialogShowing) {
      _isLoadingDialogShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showLoadingDialog(BuildContext context) {
    _isLoadingDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('권한 확인 중...'),
            ],
          ),
        ),
      ),
    ).then((_) => _isLoadingDialogShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<SplashBloc, SplashState>(listener: (context, state) {
        if (state.status == CommonStatus.loading) {
          if (_returningFromSettings) {
            _returningFromSettings = false;
            _showLoadingDialog(context);
          }
        } else {
          _dismissLoadingDialog(context);
          if (state.status == CommonStatus.success) {
            Future.delayed(const Duration(milliseconds: 3000), () {
              context.go('${state.route}');
            });
          } else if (state.status == CommonStatus.failure) {
            showAdaptiveDialog(
                context: context,
                builder: (context) {
                  return AlertDialog.adaptive(
                    title: const Text('알림'),
                    content: const Text('최신버전을 스토어에서 업데이트 해주세요'),
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
          } else if (state.status == CommonStatus.error) {
            showAdaptiveDialog(
                context: context,
                builder: (context) {
                  return AlertDialog.adaptive(
                    title: const Text('알림'),
                    content: Text('${state.errorMessage}'),
                  );
                });
          } else if (state.status == CommonStatus.dialog) {
            showPermissionDialog(context, onGoToSettings: () {
              _fromPermissionSettings = true;
            });
          }
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

                CommonStatus.success|| CommonStatus.dialog || CommonStatus.failure || CommonStatus.loading => const SvgImage("assets/images/logo_image.svg", height: 180, color: white),
                CommonStatus.initial || CommonStatus.error|| CommonStatus.code || CommonStatus.otherMdm || CommonStatus.showBlockModal => Container(
                ),
              },
            ),
          ),
        );
      }),
    );
  }
}
