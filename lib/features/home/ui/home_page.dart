import 'dart:io';

import 'package:TPASS/core/widget/qr_widget.dart';
import 'package:TPASS/main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
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
      model = iosInfo.utsname.machine;
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
            Text('제품명: ${AppConfig.to.model}'),
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
    MobileScannerController? qrViewController;
    final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

    return BlocProvider(
      create: (context) => HomeBloc(const Ticker())..add(const Initial()),
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (previous, current) =>
          previous.status != current.status ||
          (!previous.otherMdmDialogShown && current.otherMdmDialogShown),
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
            case CommonStatus.dialog:
              imageDialog(context, 'assets/images/nfc_guide.png', (){

              });
              break;
            case CommonStatus.code:
              _manualEvent(context, controller: controller, state: state, type: false, code: true);
            case CommonStatus.error:
              controller.clear();
              animatedDialog(context, state.errorMessage ?? '카메라 권한 제어 중 오류가 발생하였습니다.\n관리자에게 문의해주세요.', () {});
              break;
            case CommonStatus.failure:
              AppConfig.to.storage.write(key: 'profile_status', value: 'ban');
              // animatedDialog(context, '카메라 권한 제어 중\n비정상적인 접근이 감지되었습니다.\n관리자에게 문의해주세요. 에러코드 : ${state.ban}', () => context.go('/ban'));
              if(state.ban == "3"){
                animatedDialog(context, '프로파일이 삭제되었습니다.\n관리자에게 문의해주세요.', () => context.go('/ban'));
              }else{
                animatedDialog(context, '카메라 권한 제어 중\n비정상적인 접근이 감지되었습니다.\n관리자에게 문의해주세요. 에러코드 : ${state.ban}', () => context.go('/ban'));
              }
              break;
            case CommonStatus.otherMdm:
              if (state.otherMdmDialogShown) {
                animatedDialog(context, '다른 보안앱(MDM)에서\n카메라가 차단중입니다.\n해제 후 이용해주세요', () {
                  context.read<HomeBloc>().add(const DismissOtherMdmDialog());
                });
              }
              break;
            case CommonStatus.showBlockModal:
              // 다른 MDM 체크 후 정상이면 기능 차단 모달 표시
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
                    if (Platform.isAndroid && state.status != CommonStatus.dialog) {
                      showNFCModal(context, () => context.read<HomeBloc>().add(const Cancel()));
                    }
                    break;
                  case InteractionType.beacon:
                    context.read<HomeBloc>().add(DisableDevice(interaction));
                    break;
                  case InteractionType.manual:
                    _manualEvent(context, controller: controller, state: state, type: false, code: false);
                    break;
                  case InteractionType.delete:
                    context.read<HomeBloc>().add(const Delete());
                    break;
                  case InteractionType.location:
                    break;
                }
              });
              break;
            case CommonStatus.success:
              final code = await AppConfig.to.storage.read(key: 'code');
              final isConnected = await ConnectivityService.to.checkConnection();

              if (code != null && code.isNotEmpty && isConnected) {
                context.read<HomeBloc>().add(GetEnterPrise( code: code));
              }
              if (state.profileUrl.isNotEmpty && Platform.isIOS) {
                final AudioPlayer _audioPlayer = AudioPlayer();
                await _audioPlayer.setAudioContext(
                  AudioContext(
                    iOS: AudioContextIOS(
                      category: AVAudioSessionCategory.playback,
                      options: {
                        AVAudioSessionOptions.mixWithOthers,
                      },
                    ),
                    android: AudioContextAndroid(
                      isSpeakerphoneOn: true,
                      stayAwake: false,
                      contentType: AndroidContentType.sonification,
                      usageType: AndroidUsageType.alarm,
                      audioFocus: AndroidAudioFocus.gain,
                    ),
                  ),
                );
                await _audioPlayer.setVolume(1.0);
                await _audioPlayer.play(AssetSource('sounds/install_profile.mp3'));

                logger.d(state.profileUrl);
                await _launchUrl(state.profileUrl);
                // await HomeRepository.to.downloadFile(state.profileUrl);
                // await _launchUrl('$serverUrl/url/files/${state.profileUrl}');
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
              backgroundColor: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? colorTheme(context).overDisableBackgroundColor: colorTheme(context).overBackgroundColor,
              actions: [
                if((!state.cameraPermissionStatus.isRestricted || state.status == CommonStatus.otherMdm) && Platform.isAndroid)
                  TextButton(onPressed: (){
                    context.read<HomeBloc>().add(const Delete());
                  }, child: Text("삭제", style: TextStyle(fontSize: 20, color: Colors.red),))
              ],
              leading:
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? Colors.white :Colors.blue, size: 35,), // 파란색 아이콘
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),

            backgroundColor: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? colorTheme(context).overDisableBackgroundColor : colorTheme(context).overBackgroundColor,
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
                if (state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm)
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
                        style: textTheme(context).krTitle2R.copyWith(color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? white : null),
                      ),
                      const SizedBox(height: 16),
                      state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm
                          ? Text(
                        '차단 일시 : ${state.blockedTime.isNotEmpty ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(int.parse(state.blockedTime))) : '-'}',
                        style: textTheme(context).krTitle2R.copyWith(color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? white : null),
                      )
                          : Text('', style: textTheme(context).krTitle2R.copyWith(color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? white : null)),
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
                          height: (state.cameraPermissionStatus.isGranted || state.status == CommonStatus.otherMdm) ? null : 640,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? colorTheme(context).overDisableBackgroundColor : white,
                            boxShadow: [BoxShadow(offset: const Offset(-6, -10), blurRadius: 27, color: black.withOpacity(0.15))],
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(200)),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(top: 8, left: 8),
                            decoration: BoxDecoration(
                              color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? const Color(0xffA73131) : const Color(0xffADADAD).withOpacity(0.2),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(200)),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4, left: 4),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? colorTheme(context).overDisableBackgroundColor : white,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(200)),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 48),
                                  if (state.cameraPermissionStatus.isGranted || state.status == CommonStatus.otherMdm) const SizedBox(height: 284, child: Image(image: AssetImage('assets/images/lens.png'))),
                                  if (state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm)
                                    Container(
                                      width: 284,
                                      height: 284,
                                      decoration: BoxDecoration(
                                        color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? Colors.redAccent.withOpacity(0.3) : gray3.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Lottie.asset('assets/images/camera_spining.json'),
                                    ),
                                  const SizedBox(height: 10),
                                  if (state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm)
                                    Column(
                                      children: [
                                        // Text(state.timeAgo, style: textTheme(context).krTitle2R.copyWith(color: white, fontSize: 45)),
                                        Text(state.timeAgo, style: TextStyle(color: Colors.white, fontSize: 45, fontFamily: "Roboto")),
                                        const SizedBox(height: 16),
                                        Text('기능 차단 작동 중', style: textTheme(context).krTitle1.copyWith(color: white, fontSize: 25)),
                                      ],
                                    ),
                                  if(state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm)
                                    const SizedBox(height: 32),
                                  if(Platform.isAndroid)
                                    state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ?
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final itemCount = 5;
                                        final spacing = 8.0;
                                        final totalSpacing = spacing * (itemCount + 1);
                                        final itemWidth = (constraints.maxWidth - totalSpacing) / itemCount;
                                        final itemHeight = itemWidth * 1.14;
                                        final iconSize = itemWidth * 0.5;
                                        final fontSize = itemWidth * 0.18;

                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              width: itemWidth,
                                              height: itemHeight,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Colors.white, width: 1)
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.no_photography_outlined, size: iconSize, color: Colors.white),
                                                  Text('카메라', style: TextStyle(fontSize: fontSize, color: Colors.white))
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: itemWidth,
                                              height: itemHeight,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Colors.white, width: 1)
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.mic_off, size: iconSize, color: Colors.white),
                                                  Text('녹음', style: TextStyle(fontSize: fontSize, color: Colors.white))
                                                ],
                                              ),
                                            ),
                                            // Container(
                                            //   width: itemWidth,
                                            //   height: itemHeight,
                                            //   decoration: BoxDecoration(
                                            //       borderRadius: BorderRadius.circular(5),
                                            //       border: Border.all(color: Colors.white, width: 1)
                                            //   ),
                                            //   child: Column(
                                            //     mainAxisAlignment: MainAxisAlignment.center,
                                            //     children: [
                                            //       Icon(Icons.wifi_off, size: iconSize, color: Colors.white),
                                            //       Text('WIFI', style: TextStyle(fontSize: fontSize, color: Colors.white))
                                            //     ],
                                            //   ),
                                            // ),
                                            Container(
                                              width: itemWidth,
                                              height: itemHeight,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Colors.white, width: 1)
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.wifi_tethering_off, size: iconSize, color: Colors.white),
                                                  Text('테더링', style: TextStyle(fontSize: fontSize, color: Colors.white))
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: itemWidth,
                                              height: itemHeight,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Colors.white, width: 1)
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.usb_off, size: iconSize, color: Colors.white),
                                                  Text('USB', style: TextStyle(fontSize: fontSize, color: Colors.white))
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ):LayoutBuilder(
                                      builder: (context, constraints) {
                                        final itemCount = 5;
                                        final spacing = 8.0;
                                        final totalSpacing = spacing * (itemCount + 1);
                                        final itemWidth = (constraints.maxWidth - totalSpacing) / itemCount;
                                        final itemHeight = itemWidth * 1.14;
                                        final iconSize = itemWidth * 0.5;
                                        final fontSize = itemWidth * 0.18;

                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              width: itemWidth,
                                              height: itemHeight,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Color(0xff2F80ED), width: 1)
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.no_photography_outlined, size: iconSize, color: Colors.black),
                                                  Text('카메라', style: TextStyle(fontSize: fontSize, color: Colors.black))
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: itemWidth,
                                              height: itemHeight,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Color(0xff2F80ED), width: 1)
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.mic_off, size: iconSize, color: Colors.black),
                                                  Text('녹음', style: TextStyle(fontSize: fontSize, color: Colors.black))
                                                ],
                                              ),
                                            ),
                                            // Container(
                                            //   width: itemWidth,
                                            //   height: itemHeight,
                                            //   decoration: BoxDecoration(
                                            //       borderRadius: BorderRadius.circular(5),
                                            //       border: Border.all(color: Color(0xff2F80ED), width: 1)
                                            //   ),
                                            //   child: Column(
                                            //     mainAxisAlignment: MainAxisAlignment.center,
                                            //     children: [
                                            //       Icon(Icons.wifi_off, size: iconSize,),
                                            //       Text('WIFI', style: TextStyle(fontSize: fontSize))
                                            //     ],
                                            //   ),
                                            // ),
                                            Container(
                                              width: itemWidth,
                                              height: itemHeight,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Color(0xff2F80ED), width: 1)
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.wifi_tethering_off, size: iconSize,),
                                                  Text('테더링', style: TextStyle(fontSize: fontSize))
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: itemWidth,
                                              height: itemHeight,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Color(0xff2F80ED), width: 1)
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.usb_off, size: iconSize,),
                                                  Text('USB', style: TextStyle(fontSize: fontSize))
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  if(Platform.isAndroid)
                                    Container(height: 80,),
                                  if (state.cameraPermissionStatus.isGranted || state.status == CommonStatus.otherMdm)
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
                                                text: '[TPASS 프로필(차단)]',
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
                                                text: '[TPASS 프로필(차단)]',
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
                                                text: '[TPASS 프로필(차단)]',
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
                                                text: '[TPASS 프로필(차단)]',
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
                                  if(Platform.isAndroid && state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm)
                                    Container(height: 40,),
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
                        if (state.cameraPermissionStatus == PermissionStatus.granted || state.status == CommonStatus.otherMdm) {
                          // 다른 MDM 체크 후 showBlockModal 표시
                          context.read<HomeBloc>().add(const CheckOtherMdm());
                        } else if (state.cameraPermissionStatus == PermissionStatus.restricted && state.status != CommonStatus.otherMdm) {
                          showAcceptModal(context,state.enterPrise?.enterpriseFunction ,onClick: (interaction) {
                            switch (interaction) {
                              case InteractionType.init:
                                context.read<HomeBloc>().add(Init());
                                break;
                              case InteractionType.qr:
                              case InteractionType.nfc:
                                context.read<HomeBloc>().add(EnableDevice(interaction));
                                if (Platform.isAndroid && state.status != CommonStatus.dialog) {
                                  showNFCModal(context, () => context.read<HomeBloc>().add(const Cancel()));
                                }
                                break;
                              case InteractionType.beacon:
                                context.read<HomeBloc>().add(EnableDevice(interaction));
                                break;
                              case InteractionType.manual:
                                _manualEvent(context, controller: controller, state: state, type: true, code: false);
                                break;
                              case InteractionType.location:
                              // context.push('/location');
                                context.read<HomeBloc>().add(EnableDevice(interaction));
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
                              state.cameraPermissionStatus == PermissionStatus.restricted && state.status != CommonStatus.otherMdm  ? '기능 차단 해제' : '기능 차단',
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
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }


  _manualEvent(BuildContext context, {required TextEditingController controller, required HomeState state, required type, required code}) {
    showAdaptiveDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog.adaptive(
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code ? '안내데스크 담당자에게\n 업체코드 문의 후 입력해주세요.':
                  type ? '관리자 코드를 입력해주세요.':
                  '업체 코드를 입력해주세요.',
                  style: textTheme(context).krBody1.copyWith(fontSize: 18),
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
                  if(code == true){
                    context.read<HomeBloc>().add(Code(code: controller.text));
                  }else{
                    context.read<HomeBloc>().add(Manual(enabled: type, code: controller.text));
                  }

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
