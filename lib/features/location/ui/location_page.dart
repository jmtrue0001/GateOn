import 'dart:io';

import 'package:TPASS/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../main.dart';
import '../../home/repository/home_repository.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  var loading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            backButton: true,
            textTitle: '위치기반 해제',
            onBack: () {
              context.pop();
            },
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(color: const Color(0xffCDCFD8).withOpacity(0.1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgImage(
                          'assets/icons/ic_flag.svg',
                          color: Theme.of(context).appBarTheme.foregroundColor,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '위치기반 해제 설명',
                          style: textTheme(context).krSubtitle1,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '지정된 위치를 벗어나면 차단 해제 프로필을 설치할 수 있습니다.',
                      style: textTheme(context).krSubtext1,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Image.asset('assets/images/location_image.png'),
              const Spacer(),
              const SizedBox(height: kBottomNavigationBarHeight + 56)
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: InkWell(
            onTap: () async {
              _onLocationTap(context);
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
                  child: loading
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 24.0,
                        )
                      : Text(
                          '위치기반 해제',
                          style: textTheme(context).krTitle2.copyWith(color: white),
                        ),
                ),
              ),
            ),
          ),
        ),
        if (loading) Center(child: Container(color: black.withOpacity(0.3)))
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  _onLocationTap(BuildContext context) async {
    final code = await AppConfig.to.storage.read(key: 'code');
    setState(() {
      loading = true;
    });
    if (await Permission.location.status != PermissionStatus.granted) {
      setState(() {
        loading = false;
      });
      checkPermission(Permission.location, context, '위치');
      return;
    } else {
      await HomeRepository.to.getProfileWithLocation(code ?? '').then((value) async {
        if (Platform.isAndroid) {
          final deviceManage = await AndroidMethodChannel.to.checkDeviceAdminStatus();
          if (!deviceManage) {
            await AndroidMethodChannel.to.enableDeviceAdmin().then((value) async {
              await AndroidMethodChannel.to.enableCamera().then((value) {
                if (!value) {
                  animatedDialog(context, '차단이 해제되었습니다.', () {
                    context.pop();
                  });
                } else {
                  animatedDialog(context, '차단 해제에 오류가 발생했습니다..', () {
                    context.pop();
                  });
                }
              });
            });
          } else {
            await AndroidMethodChannel.to.enableCamera().then((value) {
              if (!value) {
                animatedDialog(context, '차단이 해제되었습니다.', () {
                  context.pop();
                });
              } else {
                animatedDialog(context, '차단 해제에 오류가 발생했습니다..', () {
                  context.pop();
                });
              }
            });
          }
        } else {
          await _launchUrl(value?.url ?? '').then((value) => context.pop());
        }
        await AppConfig.to.storage.write(key: 'profile_status', value: 'enable');
        setState(() {
          loading = false;
        });
      }).catchError((error) {
        setState(() {
          loading = false;
        });
        animatedDialog(context, error.toString(), () {});
      });
    }
  }
}
