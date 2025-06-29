import 'package:TPASS/core/core.dart';
import 'package:flutter/material.dart';

class PermissionWidget extends StatelessWidget {
  const PermissionWidget({Key? key, required this.permissionType}) : super(key: key);

  final PermissionType permissionType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: colorTheme(context).foreground, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: switch (permissionType) {
          PermissionType.camera => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgImage('assets/icons/ic_photo_camera.svg', color: colorTheme(context).foregroundText),
                    const SizedBox(width: 16),
                    Text(
                      '카메라',
                      style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).foregroundText),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('카메라 기능 차단의 정상 작동 여부 확인을 위해 사용됩니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
              ],
            ),
          PermissionType.location => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgImage('assets/icons/ic_pin_drop.svg', color: colorTheme(context).foregroundText),
                    const SizedBox(width: 16),
                    Text(
                      '위치',
                      style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).foregroundText),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('제한 구역 외에서 카메라 기능의 허용을 위해 사용됩니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
                Text('(별도의 위치정보를 수집하지 않습니다.)', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).primarySecond)),
              ],
            ),
          PermissionType.bluetooth => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.bluetooth, size: 32, color: colorTheme(context).foregroundText),
                    const SizedBox(width: 16),
                    Text(
                      '블루투스',
                      style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).foregroundText),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('카메라 기능의 차단을 위해 사용됩니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
              ],
            ),
          PermissionType.manager => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgImage('assets/icons/ic_manager.svg', color: colorTheme(context).foregroundText),
                    const SizedBox(width: 16),
                    Text(
                      '장치 관리자',
                      style: textTheme(context).krSubtitle1.copyWith(
                            color: colorTheme(context).foregroundText,
                          ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text('카메라 사용 차단 및 앱을 초기화 하지 못하도록 하기 위해 사용됩니다.', style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText)),
              ],
            )
        },
      ),
    );
  }
}
