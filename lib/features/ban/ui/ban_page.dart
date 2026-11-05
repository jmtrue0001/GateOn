import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';


import '../../../core/core.dart';
import '../../../main.dart';
import '../../home/repository/home_repository.dart';
import '../bloc/ban_bloc.dart';

class BanPage extends StatelessWidget {
  const BanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController pwController = TextEditingController();
    // 비정상 해제 시 담당자 이름·사유 입력 (감사 이력용)
    final TextEditingController managerController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    return Scaffold(
      body: BlocProvider(
        create: (context) => BanBloc()..add(const Initial()),
        child: Scaffold(
          backgroundColor: const Color(0xffF7DD21),
          body: BlocConsumer<BanBloc, BanState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              // 관리자 원격 해제(SSE) 감지 → 안내 다이얼로그 후 정상 흐름으로 재진입.
              // (확인을 누르면 splash가 상태 재평가 후 홈으로 라우팅)
              if (state.status == CommonStatus.success) {
                animatedDialog(
                  context,
                  '관리자에 의해 차단이 해제되었습니다.',
                  () => context.go('/splash'),
                );
              }
            },
            builder: (context, state) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 80),
                            Container(
                              decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(60)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                              height: 78,
                              width: double.infinity,
                              child: state.enterPrise?.enterpriseFile?.fileName == null
                                  ? const SvgImage('assets/images/logo_image.svg')
                                  : CachedNetworkImage(
                                      imageUrl: '$resourceUrl${state.enterPrise?.enterpriseFile?.fileName ?? ''}',
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) {
                                        return Container();
                                      },
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          decoration: const BoxDecoration(
                                            color: white,
                                          ),
                                        );
                                      }),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '설치 일시 : ${state.installedTime.isEmpty ? '일시가 저장되지 않음' : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(int.parse(state.installedTime)))}',
                              style: textTheme(context).krTitle2R,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 56),
                      Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xffF7DD21),
                          boxShadow: [BoxShadow(offset: const Offset(-6, -10), blurRadius: 23, color: black.withOpacity(0.15))],
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(200)),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, left: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xffADADAD).withOpacity(0.2),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(200)),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(top: 4, left: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xffF7DD21),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(200)),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 48),
                                Expanded(child: Image(fit: BoxFit.contain, image: const AssetImage('assets/images/ban_lens.png'))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                  BlurryContainer(
                    blur: 3,
                    child: Container(
                      width: 380,
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(45),
                        color: Colors.white.withOpacity(0.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SvgImage('assets/icons/ic_caution.svg'),
                          const SizedBox(height: 48),
                          AutoSizeText(
                            "비정상적인 접근이 감지되었습니다.",
                            style: textTheme(context).krTitle2.copyWith(color: black1),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AutoSizeText(
                            "관리자에 문의해주시기 바랍니다.",
                            style: textTheme(context).krSubtitle1R.copyWith(color: black1),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 58),
                          AutoSizeText(
                            "디바이스 ID",
                            style: textTheme(context).krTitle2.copyWith(color: black1),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const SvgImage('assets/icons/ic_arrow_down.svg', color: black1),
                          const SizedBox(height: 16),
                          AutoSizeText(
                            state.deviceId ?? '\n\n',
                            style: textTheme(context).krSubtitle1R.copyWith(color: black1),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: InkWell(
        onTap: () {
          showAdaptiveDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog.adaptive(
                  title: const Text(
                    '알림',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '업체코드와 관리자 코드를\n입력해주세요.',
                        style: textTheme(context).krBody1,
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.transparent,
                        child: InputWidget(
                          maxLength: 10,
                          isPassword: false,
                          isNumber: true,
                          controller: codeController,
                          hint: '업체코드',
                          errorWidget: const SizedBox(),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InputWidget(
                          maxLength: 10,
                          isPassword: true,
                          isNumber: true,
                          controller: pwController,
                          hint: '관리자 코드',
                          errorWidget: const SizedBox(),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InputWidget(
                          maxLength: 10,
                          controller: managerController,
                          hint: '담당자 이름',
                          errorWidget: const SizedBox(),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InputWidget(
                          maxLength: 40,
                          height: 80, // 해제 사유 입력란 높이를 키움
                          controller: reasonController,
                          hint: '해제 사유',
                          errorWidget: const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    adaptiveAction(
                      context: context,
                      onPressed: () {
                        pwController.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('취소', style: TextStyle(color: Colors.red)),
                    ),
                    adaptiveAction(
                      context: context,
                      onPressed: () {
                        // 담당자·사유는 감사 이력용 필수 입력 (비면 안내 후 중단)
                        if (managerController.text.trim().isEmpty || reasonController.text.trim().isEmpty) {
                          showAdaptiveDialog(
                            context: context,
                            builder: (ctx) => AlertDialog.adaptive(
                              title: const Text('알림'),
                              content: Text('담당자 이름과 해제 사유를 입력해주세요.', style: textTheme(context).krBody1),
                              actions: [adaptiveAction(context: ctx, onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        HomeRepository.to.disableBan(
                          codeController.text,
                          pwController.text,
                          manager: managerController.text.trim(),
                          reason: reasonController.text.trim(),
                        ).then((value) async {
                          if(value == true){
                            if(Platform.isAndroid){
                              await AndroidMethodChannel.to.enableCamera();
                            }
                            await AppConfig.to.writeProfileStatus('wait');
                            await AppConfig.to.storage.write(key: 'profileInstalled', value: 'false');
                            // ban 해제 후 홈으로 이동 시 진행 중이던 비콘 스캔을 확실히 중단
                            await FlutterBluePlus.stopScan();
                            context.go('/splash');
                          }

                        }).catchError((error) {
                          logger.d(error.toString());
                          showAdaptiveDialog(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog.adaptive(
                                  title: const Text(
                                    '알림',
                                  ),
                                  content: Text(
                                    '입력정보를 다시 확인해주세요.',
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
                        });
                        pwController.clear();
                      },
                      child: const Text('확인'),
                    ),
                  ],
                );
              });
        },
        child: Hero(
          tag: 'fab',
          child: Container(
            constraints: const BoxConstraints(maxHeight: 72),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(color: black, borderRadius: BorderRadius.circular(8)),
            child: SizedBox(
              child: Center(
                child: Text(
                  '관리자 허용',
                  style: textTheme(context).krTitle2.copyWith(color: colorTheme(context).activeTextColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
