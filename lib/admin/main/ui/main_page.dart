import 'package:TPASS/admin/main/bloc/main_bloc.dart';
import 'package:TPASS/admin/settings/ui/setting_page.dart';
import 'package:TPASS/admin/user/ui/user_page.dart';
import 'package:TPASS/core/core.dart';
import 'package:TPASS/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../dashboard/ui/dashboard_page.dart';
import '../../device/ui/device_page.dart';
import '../../enterprise/ui/enterprise_page.dart';
import '../../sub/ui/sub_page.dart';
import '../widget/navigation_rail_widget.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final PageController pageController;

  @override
  void initState() {
    pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MainBloc(pageController)..add(const Initial()),
      child: BlocListener<MainBloc, MainState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == CommonStatus.failure) {
            context.pushReplacement('/login');
          } else {}
        },
        child: BlocBuilder<MainBloc, MainState>(
            buildWhen: (prev, curr) => prev.status != curr.status,
            builder: (context, state) {
              return state.status == CommonStatus.initial
                  ? Container()
                  : Scaffold(
                      extendBody: true,
                      body: Row(
                        children: [
                          NavigationRailWidget(pageController: pageController),
                          Column(
                            children: [
                              BlocBuilder<MainBloc, MainState>(
                                buildWhen: (prev, curr) => prev.enterpriseInfo != curr.enterpriseInfo,
                                builder: (context, state) {
                                  return Container(
                                    height: 120,
                                    color: white,
                                    width: MediaQuery.of(context).size.width - 120,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 48.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('TPASS 매니저', style: textTheme(context).krTitle2),
                                          const Spacer(),
                                          Text('${state.enterpriseInfo?.name ?? ' '} (${state.enterpriseInfo?.loginId})', style: textTheme(context).krSubtitle1),
                                          const SizedBox(width: 24),
                                          InkWell(
                                              onTap: () {
                                                BlocProvider.of<MainBloc>(context).add(const LogOut());
                                              },
                                              child: const SvgImage('assets/icons/ic_admin_logout.svg')),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              BlocBuilder<MainBloc, MainState>(
                                builder: (context, state) {
                                  return Flexible(
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width - 120,
                                      child: PageView(
                                        physics: const NeverScrollableScrollPhysics(),
                                        controller: pageController,
                                        children: switch (AppConfig.to.secureModel.role) {
                                          Role.ROLE_ADMIN => [const EnterprisePage(), const DevicePage()],
                                          Role.ROLE_ENTERPRISE => [const DashboardPage(), const UserPage(), const DevicePage(), const SubPage(), const SettingPage()],
                                          Role.ROLE_ENTERPRISE_SUB => [const DashboardPage(), const UserPage(), const SettingPage()],
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ));
            }),
      ),
    );
  }
}
