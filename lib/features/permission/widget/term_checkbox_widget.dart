import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';

class TermCheckboxWidget extends StatelessWidget {
  const TermCheckboxWidget({Key? key, required this.termType, required this.onCheck, required this.agree}) : super(key: key);

  final TermType termType;
  final Function(bool) onCheck;
  final bool agree;

  @override
  Widget build(BuildContext context) {
    return switch (termType) {
      TermType.privacy => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  onCheck(!agree);
                },
                icon: SvgImage(agree ? 'assets/icons/ic_checkbox_active.svg' : 'assets/icons/ic_checkbox_inactive.svg', color: colorTheme(context).activeRadioColor),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: AutoSizeText.rich(
                TextSpan(
                  style: textTheme(context).krSubtext1,
                  children: <TextSpan>[
                    TextSpan(
                      text: '개인정보처리방침',
                      style: textTheme(context).krSubtext1.copyWith(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _launchUrl('http://t-pass.co.kr/personalPrivacy');
                        },
                    ),
                    TextSpan(text: '에 동의하신 후 TPASS의 기능차단 서비스를 이용하실 수 있습니다.', style: textTheme(context).krSubtext1),
                  ],
                ),
                style: textTheme(context).krSubtext1,
                maxLines: 2,
              ),
            ),
          ],
        ),
      TermType.service => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  onCheck(!agree);
                },
                icon: SvgImage(agree ? 'assets/icons/ic_checkbox_active.svg' : 'assets/icons/ic_checkbox_inactive.svg', color: colorTheme(context).activeRadioColor),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: AutoSizeText.rich(
                TextSpan(
                  style: textTheme(context).krSubtext1,
                  children: <TextSpan>[
                    TextSpan(
                      text: '서비스이용약관',
                      style: textTheme(context).krSubtext1.copyWith(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _launchUrl('http://t-pass.co.kr/term');
                        },
                    ),
                    TextSpan(text: ' 에 동의하신 후 TPASS의 기능차단 서비스를 이용하실 수 있습니다.', style: textTheme(context).krSubtext1),
                  ],
                ),
                style: textTheme(context).krSubtext1,
                maxLines: 2,
              ),
            ),
          ],
        ),
    };
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}
