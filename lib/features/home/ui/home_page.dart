import 'dart:async';
import 'dart:io';

import 'package:GateON/core/widget/qr_widget.dart';
import 'package:GateON/main.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  /// 비콘 버튼을 눌러 스캔 중인지. (스캔 중 "비콘 찾는 중..." 로딩 표시용)
  bool _beaconScanning = false;
  bool _scanDialogShowing = false;

  /// BLE 목록 다이얼로그 스크롤 컨트롤러(리스트가 길 때 스크롤바 표시용).
  final ScrollController _bleScrollController = ScrollController();

  /// 비콘 스캔 중 로딩 다이얼로그 표시. (barrier로 스캔 중 다른 조작·연타도 자연히 차단)
  void _showScanningDialog(BuildContext context) {
    if (_scanDialogShowing) return;
    _scanDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('비콘을 찾는 중...'),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissScanningDialog(BuildContext context) {
    _beaconScanning = false;
    if (!_scanDialogShowing) return;
    _scanDialogShowing = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bleScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 인앱 사파리 뷰에서 프로파일 설치 후 앱으로 복귀(resumed)하면
    // 남아있는 인앱 브라우저를 닫는다.
    if (state == AppLifecycleState.resumed) {
      closeInAppWebView();
    }
  }

  void showAboutDeviceDialog(BuildContext context) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final appInfo = await PackageInfo.fromPlatform();
    final deviceId = await AppConfig.getDeviceId();

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

    return BlocProvider(
      create: (context) => HomeBloc(const Ticker())..add(const Initial()),
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (previous, current) =>
          previous.status != current.status ||
          (!previous.otherMdmDialogShown && current.otherMdmDialogShown),
        listener: (context, state) async {
          // 비콘 스캔 로딩 다이얼로그: loading이 끝나면(다른 상태로 전이) 닫는다.
          if (state.status != CommonStatus.loading) {
            _dismissScanningDialog(context);
          }
          switch (state.status) {
            case CommonStatus.initial:
              break;
            case CommonStatus.loading:
              if (_beaconScanning) _showScanningDialog(context);
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
            case CommonStatus.storageError:
              // 앱 상태 정보를 불러오지 못함 → 다른 MDM으로 추측하지 않고 안내 (다시 시도 / 확인)
              showAdaptiveDialog(
                context: context,
                builder: (ctx) => AlertDialog.adaptive(
                  title: const Text('알림'),
                  content: Text(
                    '앱 상태 정보를 불러오지 못했습니다.\n다시 시도하거나, 계속 반복되면 관리자에게 문의해주세요.',
                    style: textTheme(context).krBody1,
                  ),
                  actions: [
                    adaptiveAction(
                      context: ctx,
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<HomeBloc>().add(Initial()); // 다시 시도 → 초기화 재실행
                      },
                      child: const Text('다시 시도'),
                    ),
                    adaptiveAction(
                      context: ctx,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
              break;
            case CommonStatus.bleList:
              _showBleListDialog(context, state.bleDevices, state.errorMessage);
              break;
            case CommonStatus.needPermission:
              // 카메라 권한 거부 → 설정 이동 안내 (비정상 처리 아님)
              animatedDialog(
                context,
                '카메라 권한이 꺼져 있습니다.\n설정에서 카메라 권한을 허용해주세요.',
                () => openAppSettings(),
              );
              break;
            case CommonStatus.failure:
              AppConfig.to.writeProfileStatus('ban');
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
                    _beaconScanning = true;
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
                await _launchUrl(context, state.profileUrl);
                // await HomeRepository.to.downloadFile(state.profileUrl);
                // await _launchUrl('$serverUrl/url/files/${state.profileUrl}');
              }
              break;
          }
        },
        builder: (context, state) {
          return Scaffold(
            // bottomSheet: const _DebugOverlay(), // [임시 디버그] 필요 시 주석 해제
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
                        '설치 일시 : ${int.tryParse(state.installedTime) != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(int.parse(state.installedTime))) : '일시가 저장되지 않음'}',
                        style: textTheme(context).krTitle2R.copyWith(color: state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm ? white : null),
                      ),
                      const SizedBox(height: 16),
                      state.cameraPermissionStatus.isRestricted && state.status != CommonStatus.otherMdm
                          ? Text(
                        '차단 일시 : ${int.tryParse(state.blockedTime) != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(int.parse(state.blockedTime))) : '-'}',
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
                                            // 테더링 항목 임시 비활성화 (나중에 재활성화 가능) — 주석 해제 시 복구
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
                                            //       Icon(Icons.wifi_tethering_off, size: iconSize, color: Colors.white),
                                            //       Text('테더링', style: TextStyle(fontSize: fontSize, color: Colors.white))
                                            //     ],
                                            //   ),
                                            // ),
                                            // USB 항목 임시 비활성화 (나중에 재활성화 가능) — 주석 해제 시 복구
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
                                            // 테더링 항목 임시 비활성화 (나중에 재활성화 가능) — 주석 해제 시 복구
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
                                            //       Icon(Icons.wifi_tethering_off, size: iconSize, color: Colors.black),
                                            //       Text('테더링', style: TextStyle(fontSize: fontSize, color: Colors.black))
                                            //     ],
                                            //   ),
                                            // ),
                                            // USB 항목 임시 비활성화 (나중에 재활성화 가능) — 주석 해제 시 복구
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
                                                text: '[게이트온 프로필(차단)]',
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
                                                text: '[게이트온 프로필(차단)]',
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
                                                text: '[게이트온 프로필(차단)]',
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
                                                text: '[게이트온 프로필(차단)]',
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
                                _beaconScanning = true;
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

  Future<void> _launchUrl(BuildContext context, String url) async {
    bool launched = false;
    try {
      // 인앱 사파리 뷰(SFSafariViewController)로 실행.
      // 기본 브라우저(크롬 등) 설정이나 Safari 앱 제한과 무관하게 Safari 엔진으로 열려
      // 프로파일 다운로드가 정상 동작한다. (externalApplication은 기본 브라우저를 따라가 실패)
      // 앱 복귀 시 남은 인앱 브라우저는 didChangeAppLifecycleState(resumed)에서 닫는다.
      launched = await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    } catch (e) {
      logger.e('launchUrl 실패: $url - $e');
      launched = false;
    }
    if (!launched && context.mounted) {
      _showLaunchFailDialog(context);
    }
  }

  /// 등록 비콘을 못 찾았을 때, 감지된 전체 BLE 목록을 스크롤 다이얼로그로 표시
  void _showBleListDialog(BuildContext context, List<String> devices, String? reason) {
    final hasReason = reason != null && reason.trim().isNotEmpty;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        title: Text(
          hasReason ? reason : '감지된 BLE 목록',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: devices.isEmpty
              ? const Text('감지된 BLE 기기가 없습니다.', style: TextStyle(fontSize: 13))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('감지된 BLE 기기 ${devices.length}개',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    // 리스트 영역 높이를 화면의 40%로 "고정"한다. 항목 수와 무관하게 항상 같은 높이,
                    // 항목이 많으면 이 안에서 스크롤한다. (maxHeight가 아니라 고정 height라 세로가 안 늘어남)
                    SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.35,
                      child: Scrollbar(
                        controller: _bleScrollController,
                        thumbVisibility: true,
                        child: ListView.separated(
                          controller: _bleScrollController,
                          // 스크롤바가 우측 내용(dBm 등)을 가리지 않도록 오른쪽 여백 확보
                          padding: const EdgeInsets.only(right: 12),
                          itemCount: devices.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (_, i) => _bleListRow(devices[i]),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인')),
        ],
      ),
    );
  }

  /// BLE 목록 한 줄. "기기ID | 신호세기 | 이름" 문자열을 파싱해
  /// 이름(강조) / 기기ID(작게) 2줄 + 신호세기(우측·강도별 색상)로 정렬 표시한다.
  Widget _bleListRow(String raw) {
    final parts = raw.split('|').map((e) => e.trim()).toList();
    final id = parts.isNotEmpty ? parts[0] : '';
    final rssi = parts.length > 1 ? parts[1] : '';
    final name = parts.length > 2 ? parts.sublist(2).join('|').trim() : '';

    final rssiVal = int.tryParse(rssi.replaceAll(RegExp(r'[^-0-9]'), ''));
    final rssiColor = rssiVal == null
        ? Colors.grey
        : (rssiVal >= -60 ? Colors.green.shade600 : (rssiVal >= -80 ? Colors.orange.shade700 : Colors.red.shade400));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? '(이름 없음)' : name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                // tagId는 진단용이라 잘리지 않게 전체 표시(길면 줄바꿈)
                Text('tag: $id',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(rssi, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: rssiColor)),
        ],
      ),
    );
  }

  void _showLaunchFailDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog.adaptive(
          title: const Text('알림'),
          content: const Text(
            '프로파일 설치 페이지를 열 수 없습니다.\n\n'
            '네트워크 연결 상태를 확인한 후 다시 시도해주세요.\n'
            '문제가 계속되면 관리자에게 문의해주세요.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }


  _manualEvent(BuildContext context, {required TextEditingController controller, required HomeState state, required type, required code}) {
    showAdaptiveDialog(
        context: context,
        barrierDismissible: false, // 바깥 영역을 눌러도 닫히지 않게 (업체코드/관리자코드 입력 팝업)
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

/// [임시 디버그] 해제/차단 프로파일 설치·삭제 시 값 변화를 화면에서 확인하기 위한 오버레이.
/// 확인이 끝나면 이 위젯과 Scaffold의 bottomSheet 라인을 제거한다.
class _DebugOverlay extends StatefulWidget {
  const _DebugOverlay();

  @override
  State<_DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<_DebugOverlay> {
  String _info = '디버그 로딩...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  Future<void> _update() async {
    if (!Platform.isIOS) {
      if (mounted) setState(() => _info = 'iOS 전용 디버그');
      return;
    }
    try {
      const platform = MethodChannel('mguard/ios/mobileconfig');
      final result = await platform.invokeMethod('isMobileConfigInstalled');
      final blockInfo = await platform.invokeMethod('getCameraBlockSource');
      final cameraRestricted = blockInfo['cameraRestricted'];
      final ps = await AppConfig.to.readProfileStatus();
      final installed = await AppConfig.to.storage.read(key: 'profileInstalled');
      if (mounted) {
        setState(() {
          _info = 'mdmInstalled: $result  /  cameraRestricted: $cameraRestricted\n'
              'profile_status: $ps  /  installed: $installed';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _info = '에러: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black.withOpacity(0.85),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        _info,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
