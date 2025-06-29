import 'package:TPASS/admin/main/bloc/main_bloc.dart';
import 'package:TPASS/core/core.dart';
import 'package:TPASS/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationRailWidget extends StatelessWidget {
  const NavigationRailWidget({Key? key, required this.pageController}) : super(key: key);

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Theme(
        data: ThemeData(
          navigationRailTheme: const NavigationRailThemeData(
            useIndicator: false,
            selectedIconTheme: IconThemeData(color: white),
            unselectedIconTheme: IconThemeData(color: white),
          ),
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: BlocBuilder<MainBloc, MainState>(
          builder: (context, state) {
            return LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: BlocBuilder<MainBloc, MainState>(
                      builder: (context, mainState) {
                        return NavigationRail(
                          onDestinationSelected: (index) {
                            context.read<MainBloc>().add(Paginate(page: index));
                          },
                          backgroundColor: blue1,
                          minWidth: 120,
                          leading: Container(
                            height: 48,
                            margin: const EdgeInsets.symmetric(vertical: 48),
                            child: const SvgImage(
                              'assets/images/logo_image.svg',
                              color: white,
                            ),
                          ),
                          destinations: navigationRailDestinations(state.page),
                          selectedIndex: state.page,
                        );
                      },
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  navigationRailDestinations(int index) {
    switch (AppConfig.to.secureModel.role) {
      case Role.ROLE_ADMIN:
        return <NavigationRailDestination>[
          NavigationRailDestination(
              icon: index == 0
                  ? Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const SvgImage('assets/icons/ic_building.svg'),
                    )
                  : Container(margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.all(8), child: const SvgImage('assets/icons/ic_building.svg')),
              label: Container()),
          NavigationRailDestination(
              icon: index == 1
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: SvgImage(
                            'assets/icons/ic_nfc.svg',
                            width: 40,
                            height: 40,
                          )),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      child: const SizedBox(width: 40, height: 40, child: SvgImage('assets/icons/ic_nfc.svg')),
                    ),
              label: Container()),
        ];
      case Role.ROLE_ENTERPRISE_SUB:
        return <NavigationRailDestination>[
          NavigationRailDestination(
              icon: index == 0
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const Icon(
                        Icons.home,
                        color: white,
                        size: 32,
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      child: const Icon(
                        Icons.home,
                        color: white,
                        size: 32,
                      ),
                    ),
              label: Container()),
          NavigationRailDestination(
              icon: index == 1
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const SvgImage('assets/icons/ic_users.svg'),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      child: const SvgImage('assets/icons/ic_users.svg'),
                    ),
              label: Container()),
          NavigationRailDestination(
              icon: index == 2
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const SvgImage('assets/icons/ic_setting.svg'),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      child: const SvgImage('assets/icons/ic_setting.svg'),
                    ),
              label: Container()),
        ];
      case Role.ROLE_ENTERPRISE:
        return <NavigationRailDestination>[
          NavigationRailDestination(
              icon: index == 0
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const Icon(
                        Icons.home_filled,
                        color: white,
                        size: 32,
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      child: const Icon(
                        Icons.home_filled,
                        color: white,
                        size: 32,
                      ),
                    ),
              label: Container()),
          NavigationRailDestination(
              icon: index == 1
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const SvgImage('assets/icons/ic_users.svg'),
                    )
                  : Container(margin: const EdgeInsets.symmetric(vertical: 8), width: 56, height: 56, child: const SvgImage('assets/icons/ic_users.svg')),
              label: Container()),
          NavigationRailDestination(
              icon: index == 2
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: SvgImage(
                            'assets/icons/ic_nfc.svg',
                          )),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      child: const SizedBox(width: 40, height: 40, child: SvgImage('assets/icons/ic_nfc.svg')),
                    ),
              label: Container()),
          NavigationRailDestination(
              icon: index == 3
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: SvgImage(
                            'assets/icons/ic_sub.svg',
                            width: 40,
                            height: 40,
                          )),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(8),
                      width: 56,
                      height: 56,
                      child: const SvgImage('assets/icons/ic_sub.svg'),
                    ),
              label: Container()),
          NavigationRailDestination(
              icon: index == 4
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xffD2D7DD).withOpacity(0.5)),
                      child: const SvgImage('assets/icons/ic_setting.svg'),
                    )
                  : Container(margin: const EdgeInsets.symmetric(vertical: 8), width: 56, height: 56, child: const SvgImage('assets/icons/ic_setting.svg')),
              label: Container()),
        ];
    }
  }
}
