import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icon_dialog/flutter_icon_dialog.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

import '../core.dart';

Widget adaptiveAction({required BuildContext context, required VoidCallback onPressed, required Widget child, bool isCancel = false}) {
  final ThemeData theme = Theme.of(context);
  switch (theme.platform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return TextButton(onPressed: onPressed, child: child);
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CupertinoDialogAction(onPressed: onPressed, textStyle: TextStyle(color: isCancel ? Colors.red : null), child: child);
  }
}

showNFCModal(context, Function() onCancel) {
  if (Platform.isAndroid) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(30)),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('스캔 준비 완료', style: textTheme(context).krTitle2R.copyWith(fontSize: 30, color: gray2)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: blue1.withOpacity(0.7), width: 5)),
                child: RippleAnimation(
                  color: blue1.withOpacity(0.5),
                  delay: const Duration(milliseconds: 300),
                  repeat: true,
                  minRadius: 40,
                  ripplesCount: 3,
                  child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: white), child: const Icon(Icons.nfc, color: blue1, size: 80)),
                ),
              ),
              const SizedBox(height: 16),
              Text('NFC를 스캔해주세요.', style: textTheme(context).krTitle1.copyWith(color: blue1)),
              const SizedBox(height: 56),
              InkWell(
                  onTap: () {
                    onCancel();
                    Navigator.pop(context);
                  },
                  child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: gray4),
                      child: Center(
                          child: Text(
                        '취소',
                        style: textTheme(context).krSubtitle1,
                      )))),
            ],
          ),
        );
      },
    );
  }
}

animatedDialog(context, String message, Function() onClick) {
  IconDialog.show(
      canGoBack: false,
      context: context,
      title: "",
      content: message,
      buttonTheme: CustomButtonTheme(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconColor: Theme.of(context).primaryColor,
        contentStyle: textTheme(context).krBody1,
      ),
      iconTitle: true,
      widgets: Container(
        decoration: const BoxDecoration(
          color: black,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8.0), bottomRight: Radius.circular(8.0)),
        ),
        width: double.infinity,
        child: TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClick();
            },
            child: Text('확인', style: textTheme(context).krBody1.copyWith(color: white))),
      ));
}

showBlockModal(context,EnterpriseFunction? enterpriseFunction, {required Function(InteractionType) onClick}) {

  Map<String, List<Widget>> modalWidget = {
    'android': [
      enterpriseFunction?.qrDisable == true || enterpriseFunction == null ?
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.qr);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code),
              const SizedBox(width: 16),
              Text(
                'QR코드로 차단',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ):Container(),
      enterpriseFunction?.beaconDisable == true || enterpriseFunction == null ?
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.beacon);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth_outlined),
              const SizedBox(width: 16),
              Text(
                '비콘으로 차단',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ):Container(),
      enterpriseFunction?.nfcDisable == true || enterpriseFunction == null ?
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.nfc);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.sensors_outlined),
              const SizedBox(width: 16),
              Text(
                'NFC로 차단',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ):Container(),
      enterpriseFunction?.manualDisable == true || enterpriseFunction == null ?
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.manual);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_outlined),
              const SizedBox(width: 16),
              Text(
                '업체코드로 차단',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ):Container(),
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.init);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.refresh),
              const SizedBox(width: 16),
              Text(
                '차단방법 전체보기',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ),
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.delete);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              const SizedBox(width: 16),
              Text(
                '앱 삭제',
                style: textTheme(context).krSubtitle1R.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    ],
    'iOS': [
      enterpriseFunction?.qrDisable == true || enterpriseFunction == null?
      CupertinoActionSheetAction(
        child: Text('QR코드로 차단', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.qr);
        },
      ):Container(),
      enterpriseFunction?.beaconDisable == true || enterpriseFunction == null?
      CupertinoActionSheetAction(
        child: Text('비콘으로 차단', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.beacon);
        },
      ):Container(),
      enterpriseFunction?.nfcDisable == true || enterpriseFunction == null?
      CupertinoActionSheetAction(
        child: Text('NFC로 차단', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.nfc);
        },
      ):Container(),
      enterpriseFunction?.manualDisable == true || enterpriseFunction == null?
      CupertinoActionSheetAction(
        child: Text('업체코드로 차단', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.manual);
        },
      ):Container(),
      CupertinoActionSheetAction(
        child: Text('차단방법 전체보기', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.init);
        },
      ),
    ],
  };

  if (defaultTargetPlatform == TargetPlatform.android) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      barrierColor: black.withOpacity(0.7),
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: colorTheme(context).background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('기능 차단 방법', style: textTheme(context).krBody1.copyWith(color: gray2))),
                const SizedBox(height: 16),
                for (var widget in modalWidget['android'] ?? []) widget,
              ],
            ),
          ),
        );
      },
    );
  } else {
    showCupertinoModalPopup<void>(
      barrierColor: black.withOpacity(0.7),
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: Text('기능 차단 방법', style: textTheme(context).krSubtext1),
        actions: modalWidget['iOS'],
        cancelButton: CupertinoActionSheetAction(
          child: Text('취소', style: textTheme(context).krTitle2R.copyWith(color: Colors.red)),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

showAcceptModal(context,EnterpriseFunction? enterpriseFunction,{required Function(InteractionType) onClick}) {
  Map<String, List<Widget>> modalWidget = {
    'android': [
      enterpriseFunction?.beaconEnable == true || enterpriseFunction == null?
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.beacon);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth_outlined),
              const SizedBox(width: 16),
              Text(
                '비콘으로 차단 해제',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ):Container(),
      enterpriseFunction?.locationEnable == true || enterpriseFunction == null?
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.location);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.location_pin),
              const SizedBox(width: 16),
              Text(
                '위치기반으로 차단 해제',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ):Container(),
      enterpriseFunction?.nfcEnable == true || enterpriseFunction == null?
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.nfc);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.sensors_outlined),
              const SizedBox(width: 16),
              Text(
                'NFC로 차단 해제',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ) : Container(),

      enterpriseFunction?.manualEnable == true || enterpriseFunction == null?
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.manual);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_outlined),
              const SizedBox(width: 16),
              Text(
                '관리자코드로 차단 해제',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ):Container(),
      Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onClick(InteractionType.init);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.refresh),
              const SizedBox(width: 16),
              Text(
                '차단방법 전체보기',
                style: textTheme(context).krSubtitle1R,
              ),
            ],
          ),
        ),
      ),
    ],
    'iOS': [
      enterpriseFunction?.beaconEnable == true || enterpriseFunction == null?
      CupertinoActionSheetAction(
        child: Text('비콘으로 차단 해제', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.beacon);
        },
      ):Container(),
      enterpriseFunction?.locationEnable == true || enterpriseFunction == null?
      CupertinoActionSheetAction(
        child: Text('위치기반으로 차단 해제', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.location);
        },
      ):Container(),
      enterpriseFunction?.nfcEnable == true || enterpriseFunction == null?
      CupertinoActionSheetAction(
        child: Text('NFC으로 차단 해제', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.nfc);
        },
      ):Container(),
      enterpriseFunction?.manualEnable == true || enterpriseFunction == null?
      CupertinoActionSheetAction(
        child: Text('관리자로 차단 해제', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.manual);
        },
      ):Container(),
      CupertinoActionSheetAction(
        child: Text('차단방법 전체보기', style: textTheme(context).krTitle2R.copyWith(color: Colors.blueAccent)),
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          onClick(InteractionType.init);
        },
      ),
    ],
  };

  if (defaultTargetPlatform == TargetPlatform.android) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      barrierColor: black.withOpacity(0.7),
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: colorTheme(context).background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('기능 차단 해제 방법', style: textTheme(context).krBody1.copyWith(color: gray2))),
                const SizedBox(height: 16),
                for (var widget in modalWidget['android'] ?? []) widget,
              ],
            ),
          ),
        );
      },
    );
  } else {
    showCupertinoModalPopup<void>(
      barrierColor: black.withOpacity(0.7),
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: Text('카메라 차단 해제 방법', style: textTheme(context).krSubtext1),
        actions: modalWidget['iOS'],
        cancelButton: CupertinoActionSheetAction(
          child: Text('취소', style: textTheme(context).krTitle2R.copyWith(color: Colors.red)),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

dialog(BuildContext context, Widget widget) {
  showDialog<void>(
    barrierDismissible: true,
    barrierColor: black.withOpacity(0.1),
    context: context,
    builder: (BuildContext ctx) {
      return widget;
    },
  );
}
