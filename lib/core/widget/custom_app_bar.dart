import 'package:flutter/material.dart';

import '../core.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, this.backButton = false, this.onBack, this.textTitle = '', this.actions = const [], this.bottom, this.widgetTitle, this.leadingAction, this.color, this.iconColor}) : super();

  final bool backButton;
  final Function()? onBack;
  final String textTitle;
  final List<Widget> actions;
  final Widget? leadingAction;
  final Widget? widgetTitle;
  final PreferredSizeWidget? bottom;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
            bottom: bottom,
            elevation: 0,
            leading: leadingAction ??
                (backButton
                    ? IconButton(
                        splashRadius: 24,
                        onPressed: onBack,
                        icon: SvgImage(
                          'assets/icons/ic_arrow_left.svg',
                          color: Theme.of(context).appBarTheme.foregroundColor,
                        ))
                    : const SizedBox(
                        width: 0,
                      )),
            title: widgetTitle ??
                (textTitle.isNotEmpty
                    ? Text(textTitle, style: Theme.of(context).appBarTheme.titleTextStyle)
                    : Hero(
                        tag: 'logo',
                        child: SvgImage(
                          'assets/images/logo_image_horizontal.svg',
                          height: 40,
                          color: iconColor ?? colorTheme(context).logoColor,
                        ),
                      )),
            centerTitle: textTitle.isEmpty ? false : true,
            actions: actions,
            leadingWidth: backButton
                ? 56
                : leadingAction == null
                    ? 8
                    : 56,
            backgroundColor: color ?? Theme.of(context).appBarTheme.backgroundColor),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
