import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../widget/guide_text.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: kToolbarHeight,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Hero(
                            tag: 'logo',
                            child: SvgImage(
                              'assets/images/logo_image_mini.svg',
                              height: 40,
                              color: colorTheme(context).logoColor,
                            )),
                        const SizedBox(width: 16),
                        Text(
                          '앱 이용 안내',
                          style: textTheme(context).krTitle1.copyWith(color: colorTheme(context).primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('TPASS는 스마트폰의 기능(카메라, 녹음) 사용을 제어 합니다.', style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).titleText)),
                    const SizedBox(height: 16),
                    Platform.isIOS ?
                    Text('카메라 제어를 위해 프로필의 설치가 필요합니다.', style: textTheme(context).krBody1)
                    : Container()
                    ,
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: colorTheme(context).foreground, borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.no_photography_outlined,
                                color: colorTheme(context).foregroundText,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Platform.isAndroid ?
                              Text('기능 차단 방법', style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).foregroundText)) :
                              Text('TPASS 프로필(차단) 설치 방법', style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).foregroundText))
                              ,
                            ],
                          ),
                          const SizedBox(height: 16),
                          Platform.isAndroid?
                          GuideText(
                            1,
                            textSpan: [
                              TextSpan(
                                text: '기능 차단버튼 → 차단방법(QR코드, 비콘, NFC, 업체코드)',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: colorTheme(context).foregroundText),
                              ),
                              TextSpan(text: '선택', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ):GuideText(
                            1,
                            textSpan: [
                              TextSpan(text: '[TPASS 프로필(차단)] 다운로드', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Platform.isAndroid?
                          GuideText(
                            2,
                            textSpan: [
                              TextSpan(
                                text: '차단 방법별로 진행',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: colorTheme(context).foregroundText),
                              ),
                              // TextSpan(text: '을 인식합니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ):GuideText(
                            2,
                            textSpan: [
                              TextSpan(
                                text: '아이폰 설정 열기',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: Colors.yellow),
                              ),
                              // TextSpan(text: '을 인식합니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Platform.isAndroid?
                          GuideText(
                            3,
                            textSpan: [
                              TextSpan(
                                text: '스마트폰 기능 차단',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: colorTheme(context).foregroundText),
                              ),
                              // TextSpan(text: '을 다운로드 및 설치 합니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ):GuideText(
                            3,
                            textSpan: [
                              TextSpan(text: '[프로필 다운로드됨] 선택', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                          Platform.isAndroid?
                              Container():
                          const SizedBox(height: 8),
                          Platform.isAndroid?
                          Container():
                          GuideText(
                            4,
                            textSpan: [
                              TextSpan(text: '[TPASS 프로필 (차단)] 설치', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                          Platform.isAndroid?
                          Container():
                          const SizedBox(height: 8),
                          Platform.isAndroid?
                          Container():
                          GuideText(
                            5,
                            textSpan: [
                              TextSpan(text: '스마트폰 기능 차단', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(color: colorTheme(context).foreground, borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: colorTheme(context).foregroundText,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Platform.isAndroid?
                              Text('기능 허용(차단 해제) 방법', style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).foregroundText)):
                              Text('TPASS 프로필(차단 해제) 설치 방법', style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).foregroundText))
                              ,
                            ],
                          ),
                          const SizedBox(height: 16),
                          Platform.isAndroid?
                          GuideText(
                            1,
                            textSpan: [
                              TextSpan(
                                text: '기능 차단 해제버튼 → 차단해제 방법(비콘, 위치기반, NFC, 업체코드)',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: colorTheme(context).foregroundText),
                              ),
                              TextSpan(text: '선택', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ):
                          GuideText(
                            1,
                            textSpan: [
                              TextSpan(
                                text: '[TPASS 프로필(차단해제)] ',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: colorTheme(context).foregroundText),
                              ),
                              TextSpan(text: '다운로드', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Platform.isAndroid?
                          GuideText(
                            2,
                            textSpan: [
                              TextSpan(
                                text: '차단해제 방법별로 진행',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: colorTheme(context).foregroundText),
                              ),
                              // TextSpan(text: '을 인식합니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ):GuideText(
                            2,
                            textSpan: [
                              TextSpan(
                                text: '아이폰 설정 열기',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: Colors.yellow),
                              ),
                              // TextSpan(text: '을 인식합니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Platform.isAndroid?
                          GuideText(
                            3,
                            textSpan: [
                              TextSpan(
                                text: '스마트폰 기능 차단해제',
                                style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: colorTheme(context).foregroundText),
                              ),
                              // TextSpan(text: '을 다운로드 및 설치 합니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ):GuideText(
                            3,
                            textSpan: [
                              TextSpan(text: '[프로필 다운로드됨] 선택', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                          Platform.isAndroid?
                          Container():
                          const SizedBox(height: 8),
                          Platform.isAndroid?
                          Container():
                          GuideText(
                            4,
                            textSpan: [
                              TextSpan(text: '[TPASS 프로필 (차단해제)] 설치', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                          Platform.isAndroid?
                          Container():
                          const SizedBox(height: 8),
                          Platform.isAndroid?
                          Container():
                          GuideText(
                            5,
                            textSpan: [
                              TextSpan(text: '스마트폰 기능 차단해제', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 32),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
              //   child: AutoSizeText.rich(
              //     TextSpan(
              //       children: [
              //         TextSpan(
              //           text: '‣ 방문 업체에서 퇴장하면 ',
              //           style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).titleText),
              //         ),
              //         TextSpan(
              //           text: '[위치기반 해제]',
              //           style: textTheme(context).krSubtext1.copyWith(fontWeight: FontWeight.bold, color: colorTheme(context).titleText),
              //         ),
              //         TextSpan(
              //           text: ' 버튼이 활성화되며, 해당 버튼을 누를 시 카메라 허용 프로필을 다운로드 및 설치할 수 있습니다.',
              //           style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).titleText),
              //         ),
              //       ],
              //     ),
              //     style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).titleText),
              //     maxLines: 3,
              //   ),
              // ),
              const SizedBox(
                height: kBottomNavigationBarHeight + 56,
              )
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: InkWell(
        onTap: () {
          context.go('/');
          HapticFeedback.mediumImpact();
        },
        child: Hero(
          tag: 'fab',
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              constraints: const BoxConstraints(maxHeight: 72),
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(color: colorTheme(context).activeButton, borderRadius: BorderRadius.circular(8)),
              child: SizedBox(
                child: Center(
                  child: Text(
                    '확인',
                    style: textTheme(context).krTitle2.copyWith(color: colorTheme(context).activeTextColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
