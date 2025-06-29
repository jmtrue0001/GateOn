import 'package:flutter/material.dart';

import '../../../core/core.dart';

class DataTileContainer extends StatelessWidget {
  const DataTileContainer({Key? key, this.width, this.height, required this.child, this.minHeight, this.maxWidth, this.maxHeight}) : super(key: key);

  final double? width;
  final double? height;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: BoxConstraints(minHeight: minHeight ?? 0, maxWidth: maxWidth ?? double.infinity, maxHeight: maxHeight ?? double.infinity),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: white,
        boxShadow: [
          BoxShadow(color: black.withOpacity(0.1), offset: const Offset(-20, -10), spreadRadius: -11, blurRadius: 39),
          BoxShadow(color: black.withOpacity(0.15), offset: const Offset(0, 4), spreadRadius: -13, blurRadius: 41),
        ],
      ),
      child: child,
    );
  }
}
