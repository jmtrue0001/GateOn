import 'package:flutter/material.dart';

import '../../../core/core.dart';

class StatsTitleWidget extends StatelessWidget {
  const StatsTitleWidget({Key? key, required this.child, required this.text, required this.buttons}) : super(key: key);

  final Widget child;
  final List<Widget> buttons;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        width: MediaQuery.of(context).size.width - 120,
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      style: textTheme(context).krTitle1,
                    )),
                const Spacer(),
                for (Widget widget in buttons) widget,
              ],
            ),
            const SizedBox(height: 53),
            child
          ],
        ),
      ),
    );
  }
}
