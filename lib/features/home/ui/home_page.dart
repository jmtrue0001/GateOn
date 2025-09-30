import 'dart:io';

import 'package:TPASS/core/widget/qr_widget.dart';
import 'package:TPASS/main.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:icon_animated/icon_animated.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../bloc/home_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
  void showAboutDeviceDialog(BuildContext context) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final appInfo = await PackageInfo.fromPlatform();
    final deviceId = await AppConfig.to.storage.read(key: "deviceId");

    String manufacturer = '';
    String model = '';
    String osVersion = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      manufacturer = androidInfo.manufacturer;
      model = androidInfo.model;
      osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      manufacturer = 'Apple';
      model = iosInfo.utsname.machine ?? 'iOS Device';
      osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('시스템 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('제조사: ${AppConfig.to.manufacturer}'),
            Text('모델명: ${AppConfig.to.model}'),
            Text('OS 버전: ${AppConfig.to.osVersion}'),
            Text('디바이스 ID: $deviceId'),
            Text('앱 버전: ${AppConfig.to.appVersion}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    QRViewController? qrViewController;
    final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
    return BlocProvider(
      create: (context) => HomeBloc(const Ticker())..add(const Initial()),
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) async {
          switch (state.status) {
            case CommonStatus.initial:
              final code = await AppConfig.to.storage.read(key: 'code');
              if (code != null && code.isNotEmpty) {
                context.read<HomeBloc>().add(GetEnterPrise(code: code));
              }
              break;
            case CommonStatus.loading:
              break;
            case CommonStatus.error:
              controller.clear();
              animatedDialog(context, state.errorMessage ?? '카메라 권한 제어 중 오류가 발생하였습니다.\n관리자에게 문의해주세요.', () {});
              break;
            case CommonStatus.failure:
              AppConfig.to.storage.write(key: 'profile_status', value: 'ban');
              // animatedDialog(context, '카메라 권한 제어 중\n비정상적인 접근이 감지되었습니다.\n관리자에게 문의해주세요. 에러코드 : ${state.ban}', () => context.go('/ban'));
              animatedDialog(context, '카메라 권한 제어 중\n비정상적인 접근이 감지되었습니다.\n관리자에게 문의해주세요.', () => context.go('/ban'));
              break;
            case CommonStatus.success:
              final code = await AppConfig.to.storage.read(key: 'code');
              logger.d(code);

              if (code != null && code.isNotEmpty) {
                context.read<HomeBloc>().add(GetEnterPrise(code: code));
              }
              if (state.profileUrl.isNotEmpty && Platform.isIOS) {
                logger.d(state.profileUrl);
                await _launchUrl(state.profileUrl);
              }
              break;
          }
        },
        builder: (context, state) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            extendBody: true,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              // forceMaterialTransparency: true,
              automaticallyImplyLeading: true,
              bottomOpacity: 0,
              scrolledUnderElevation: 0,
              // backgroundColor: Colors.transparent,
              backgroundColor: !state.cameraPermissionStatus.isRestricted ? colorTheme(context).overBackgroundColor : colorTheme(context).overDisableBackgroundColor,
              actions: [
                if(!state.cameraPermissionStatus.isRestricted && Platform.isAndroid)
                TextButton(onPressed: (){
                  context.read<HomeBloc>().add(const Delete());
                }, child: Text("삭제", style: TextStyle(fontSize: 20, color: Colors.red),))
              ],
              leading:
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: state.cameraPermissionStatus.isRestricted ? Colors.white :Colors.blue, size: 35,), // 파란색 아이콘
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),

            backgroundColor: state.cameraPermissionStatus.isRestricted ? colorTheme(context).overDisableBackgroundColor : colorTheme(context).overBackgroundColor,
            drawer:
            Drawer(
              child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(height: 100,),
                Divider(),
                // ListTile(
                //   leading: Icon(Icons.settings),
                //   title: Text('앱 설정'),
                //   onTap: () {
                //     Navigator.pop(context);
                //     // 앱 설정 페이지 이동 or dialog
                //   },
                // ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('시스템 정보'),
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDeviceDialog(context);
                  },
                ),
                // ListTile(
                //   leading: Icon(Icons.question_mark_outlined),
                //   title: Text('가이드'),
                //   onTap: () {
                //     Navigator.pop(context);
                //     showAboutDeviceDialog(context);
                //   },
                // ),
                // if (state.cameraPermissionStatus.isRestricted)
                // ListTile(
                //   leading: Icon(Icons.restart_alt_outlined, color: Colors.redAccent),
                //   title: Text('관리자 초기화', style: TextStyle(color: Colors.redAccent)),
                //   onTap: () async {
                //     Navigator.pop(context);
                //
                //   },
                // ),

              ],
            ),
            ),
            body: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (state.cameraPermissionStatus.isRestricted)
                  Lottie.asset(
                    'assets/images/background.json',
                  ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 100),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(60)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                        height: 78,
                        width: double.infinity,
                        child: state.enterPrise?.enterpriseFile?.fileName == null
                            ? const SvgImage('assets/images/logo_image_horizontal.svg')
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
                        style: textTheme(context).krTitle2R.copyWith(color: state.cameraPermissionStatus.isRestricted ? white : null),
                      ),
                      const SizedBox(height: 16),
                      state.cameraPermissionStatus.isRestricted
                          ? Text(
                              '차단 일시 : ${state.blockedTime.isNotEmpty ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(int.parse(state.blockedTime))) : '-'}',
                              style: textTheme(context).krTitle2R.copyWith(color: state.cameraPermissionStatus.isRestricted ? white : null),
                            )
                          : Text('', style: textTheme(context).krTitle2R.copyWith(color: state.cameraPermissionStatus.isRestricted ? white : null)),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    color: Colors.white.withOpacity(0),
                    margin: const EdgeInsets.only(top: 300),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: state.cameraPermissionStatus.isGranted ? null : 640,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: state.cameraPermissionStatus.isRestricted ? colorTheme(context).overDisableBackgroundColor : white,
                            boxShadow: [BoxShadow(offset: const Offset(-6, -10), blurRadius: 27, color: black.withOpacity(0.15))],
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(200)),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(top: 8, left: 8),
                            decoration: BoxDecoration(
                              color: state.cameraPermissionStatus.isRestricted ? const Color(0xffA73131) : const Color(0xffADADAD).withOpacity(0.2),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(200)),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4, left: 4),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: state.cameraPermissionStatus.isRestricted ? colorTheme(context).overDisableBackgroundColor : white,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(200)),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 48),
                                  if (state.cameraPermissionStatus.isGranted) const SizedBox(height: 284, child: Image(image: AssetImage('assets/images/lens.png'))),
                                  if (state.cameraPermissionStatus.isRestricted)
                                    Container(
                                      width: 284,
                                      height: 284,
                                      decoration: BoxDecoration(
                                        color: state.cameraPermissionStatus.isRestricted ? Colors.redAccent.withOpacity(0.3) : gray3.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Lottie.asset('assets/images/camera_spining.json'),
                                    ),
                                  const SizedBox(height: 40),
                                  if (state.cameraPermissionStatus.isRestricted)
                                    Column(
                                      children: [
                                        Text('기능 차단 작동 중', style: textTheme(context).krTitle1.copyWith(color: white, fontSize: 25)),
                                        const SizedBox(height: 32),
                                        Text(state.timeAgo, style: textTheme(context).krTitle2R.copyWith(color: white, fontSize: 24)),
                                      ],
                                    ),
                                  if(state.cameraPermissionStatus.isRestricted)
                                  const SizedBox(height: 32),
                                  if(Platform.isAndroid)
                                    state.cameraPermissionStatus.isRestricted ?
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Spacer(),
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration:
                                          BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(color: Colors.white, width: 1)
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.no_photography_outlined,size: 40,),
                                              Text('카메라', style: TextStyle(fontSize: 16),)
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: Colors.white, width: 1)
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.mic_off, size: 40,),
                                              Text('녹음')
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                      ],
                                    ):Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Spacer(),
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration:
                                          BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: Color(0xff2F80ED), width: 1)
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.no_photography_outlined,size: 40,),
                                              Text('카메라', style: TextStyle(fontSize: 16),)
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(color: Color(0xff2F80ED), width: 1)
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.mic_off, size: 40,),
                                              Text('녹음')
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                      ],
                                    ),
                                  if(Platform.isAndroid)
                                    Container(height: 40,),
                                  if (state.cameraPermissionStatus.isGranted)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Center(child: Text('기능 차단 가이드', style: textTheme(context).krTitle1.copyWith(color: const Color(0xff7B878D), fontSize: 25))),
                                        const SizedBox(height: 32),
                                        const Center(child: SvgImage('assets/icons/ic_arrow_down.svg')),
                                        const SizedBox(height: 40),
                                        Text('QR코드로 차단', style: textTheme(context).krSubtitle1.copyWith(color: const Color(0xff7B878D))),
                                        const SizedBox(height: 24),
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '1단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '[QR코드로 차단] ',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '선택')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '2단계 : ',
                                            children: [
                                              TextSpan(
                                                text: 'QR코드',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '스캔')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Platform.isAndroid?
                                        AutoSizeText.rich(
                                          const TextSpan(
                                            text: '3단계 : ',
                                            children: [
                                              TextSpan(text: '기능 차단 완료')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ):
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '3단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '[TPASS 프로파일(차단)]',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '다운로드 및 설치')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Platform.isAndroid?
                                        Container():
                                        AutoSizeText.rich(
                                          const TextSpan(
                                            text: '4단계 : ',
                                            children: [
                                              TextSpan(text: '기능 차단 완료')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 40),
                                        Text('비콘으로 차단', style: textTheme(context).krSubtitle1.copyWith(color: const Color(0xff7B878D))),
                                        const SizedBox(height: 16),
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '1단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '[비콘으로 차단] ',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '선택')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '2단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '비콘 자동인식',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Platform.isAndroid?
                                        AutoSizeText.rich(
                                          const TextSpan(
                                            text: '3단계 : ',
                                            children: [
                                              TextSpan(text: '기능 차단 완료')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ):
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '3단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '[TPASS 프로파일(차단)]',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '다운로드 및 설치')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Platform.isAndroid?
                                        Container():
                                        AutoSizeText.rich(
                                          const TextSpan(
                                            text: '4단계 : ',
                                            children: [
                                              TextSpan(text: '기능 차단 완료')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 40),
                                        Text('NFC로 차단', style: textTheme(context).krSubtitle1.copyWith(color: const Color(0xff7B878D))),
                                        const SizedBox(height: 24),
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '1단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '[NFC로 차단] ',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '선택')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '2단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '차단 NFC',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '태그')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Platform.isAndroid?
                                        AutoSizeText.rich(
                                          const TextSpan(
                                            text: '3단계 : ',
                                            children: [
                                              TextSpan(text: '기능 차단 완료')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ):
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '3단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '[TPASS 프로파일(차단)]',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '다운로드 및 설치')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Platform.isAndroid?
                                        Container():
                                        AutoSizeText.rich(
                                          const TextSpan(
                                            text: '4단계 : ',
                                            children: [
                                              TextSpan(text: '기능 차단 완료')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 40),
                                        Text('업체코드로 차단', style: textTheme(context).krSubtitle1.copyWith(color: const Color(0xff7B878D))),
                                        const SizedBox(height: 24),
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '1단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '[업체코드로 차단] ',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '선택')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '2단계 : ',
                                            children: [
                                              TextSpan(
                                                text: "'업체코드'",
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '입력')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Platform.isAndroid?
                                        AutoSizeText.rich(
                                          const TextSpan(
                                            text: '3단계 : ',
                                            children: [
                                              TextSpan(text: '기능 차단 완료')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ):
                                        AutoSizeText.rich(
                                          TextSpan(
                                            text: '3단계 : ',
                                            children: [
                                              TextSpan(
                                                text: '[TPASS 프로파일(차단)]',
                                                style: textTheme(context).krBody2.copyWith(color: const Color(0xff7B878D)),
                                              ),
                                              const TextSpan(text: '다운로드 및 설치')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 16),
                                        Platform.isAndroid?
                                        Container():
                                        AutoSizeText.rich(
                                          const TextSpan(
                                            text: '4단계 : ',
                                            children: [
                                              TextSpan(text: '기능 차단 완료')
                                            ],
                                          ),
                                          textAlign: TextAlign.left,
                                          style: textTheme(context).krBody1.copyWith(color: const Color(0xff7B878D)),
                                          maxLines: 2,
                                        ),

                                        const SizedBox(height: kBottomNavigationBarHeight + 16 + 64),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.status == CommonStatus.loading) Center(child: Container(color: black.withOpacity(0.3)))
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (previous, current) => previous.status != current.status || previous.cameraPermissionStatus != current.cameraPermissionStatus || previous.enterPrise != current.enterPrise,
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {
                        if (state.status == CommonStatus.loading) {
                          context.read<HomeBloc>().add(const Cancel());
                          return;
                        }
                        if (state.cameraPermissionStatus == PermissionStatus.granted) {
                          showBlockModal(context, state.enterPrise?.enterpriseFunction, onClick: (interaction) {
                            switch (interaction) {
                              case InteractionType.init:
                                context.read<HomeBloc>().add(Init());
                                break;
                              case InteractionType.qr:
                                showDialog(context: context, builder: (BuildContext ctx){
                                  return QrWidget(bloc:context.read<HomeBloc>());
                                });
                              case InteractionType.nfc:
                                context.read<HomeBloc>().add(DisableDevice(interaction));
                                if (Platform.isAndroid) {
                                  showNFCModal(context, () => context.read<HomeBloc>().add(const Cancel()));
                                }
                                break;
                              case InteractionType.beacon:
                                context.read<HomeBloc>().add(DisableDevice(interaction));
                                break;
                              case InteractionType.manual:
                                _manualEvent(context, controller: controller, state: state, type: false);
                                break;
                              case InteractionType.delete:
                                context.read<HomeBloc>().add(const Delete());
                                break;
                              case InteractionType.location:
                                break;
                            }
                          });
                        } else if (state.cameraPermissionStatus == PermissionStatus.restricted) {
                          showAcceptModal(context,state.enterPrise?.enterpriseFunction ,onClick: (interaction) {
                            switch (interaction) {
                              case InteractionType.init:
                                context.read<HomeBloc>().add(Init());
                                break;
                              case InteractionType.qr:
                              case InteractionType.nfc:
                                context.read<HomeBloc>().add(EnableDevice(interaction));
                                if (Platform.isAndroid) {
                                  showNFCModal(context, () => context.read<HomeBloc>().add(const Cancel()));
                                }
                                break;
                              case InteractionType.beacon:
                                context.read<HomeBloc>().add(EnableDevice(interaction));
                                break;
                              case InteractionType.manual:
                                _manualEvent(context, controller: controller, state: state, type: true);
                                break;
                              case InteractionType.location:
                                context.push('/location');
                                break;

                              case InteractionType.delete:
                                context.read<HomeBloc>().add(const Delete());
                                break;
                            }
                          });
                        }
                      },
                      child: Hero(
                        tag: 'fab',
                        child: Material(
                          color: Colors.transparent,
                          child: AnimatedContainer(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(maxHeight: 72),
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                            decoration: BoxDecoration(color: colorTheme(context).profileButtonColor, borderRadius: BorderRadius.circular(8)),
                            child: state.status == CommonStatus.loading
                                ? const SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 24.0,
                                  )
                                : Text(
                                    state.cameraPermissionStatus == PermissionStatus.granted ? '기능 차단' : '기능 차단 해제',
                                    style: textTheme(context).krTitle2.copyWith(color: white),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }


  _manualEvent(BuildContext context, {required TextEditingController controller, required HomeState state, required type}) {
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
                  type ? '관리자 코드를 입력해주세요.':
                  '업체 코드를 입력해주세요.',
                  style: textTheme(context).krBody1,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: InputWidget(
                      maxLength: 10,
                      isPassword: true,
                      isNumber: true,
                      controller: controller,
                      filled: true,
                      hint: '',
                      errorWidget: state.status == CommonStatus.failure ? Text('${state.errorMessage}', style: textTheme(context).krSubtext1.copyWith(color: Colors.red)) : const SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              adaptiveAction(
                context: context,
                onPressed: () {
                  controller.clear();
                  Navigator.pop(context);
                },
                child: const Text('취소', style: TextStyle(color: Colors.red)),
              ),
              adaptiveAction(
                context: context,
                onPressed: () {
                  context.read<HomeBloc>().add(Manual(enabled: type, code: controller.text));
                  controller.clear();
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ],
          );
        });
  }
}
