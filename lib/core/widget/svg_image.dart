import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgImage extends StatelessWidget {
  const SvgImage(this.assetName, {Key? key, this.color, this.height, this.width}) : super(key: key);

  final String assetName;
  final Color? color;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ColorFilter? colorFilter = color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn);

    return SvgPicture.asset(assetName, colorFilter: colorFilter, height: height, width: width);
  }
}
