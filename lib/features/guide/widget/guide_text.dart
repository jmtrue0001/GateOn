import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../core/core.dart';

class GuideText extends StatelessWidget {
  const GuideText(this.step, {Key? key, required this.textSpan}) : super(key: key);

  final int step;
  final List<TextSpan> textSpan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$step단계 : ',
          textAlign: TextAlign.right,
          style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: AutoSizeText.rich(
            TextSpan(
              text: '',
              children: textSpan,
            ),
            textAlign: TextAlign.left,
            style: textTheme(context).krSubtext1.copyWith(color: colorTheme(context).foregroundText),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
