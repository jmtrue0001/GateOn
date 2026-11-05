import 'package:GateON/admin/main/bloc/main_bloc.dart';
import 'package:GateON/admin/main/widget/account_dialog.dart';
import 'package:GateON/admin/settings/ui/setting_page.dart';
import 'package:GateON/admin/user/ui/user_page.dart';
import 'package:GateON/core/core.dart';
import 'package:GateON/main.dart';
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

  // 최초 로그인 강제 변경 다이얼로그 중복 표시 방지 플래그.
  bool _accountSetupPrompted = false;

  @override
  void initState() {
    pageController = PageController(initialPage: 0);
    super.initState();
  }

  // 최고관리자가 최초 로그인(비밀번호 미변경) 상태이면 취소 불가 계정 변경 다이얼로그를 강제로 띄운다.
  void _maybePromptAccountSetup(BuildContext context) {
    if (_accountSetupPrompted) return;
    final needsSetup = AppConfig.to.secureModel.role == Role.ROLE_ADMIN &&
        AppConfig.to.shared.getBool('isPasswordChanged') == false;
    if (!needsSetup) return;
    _accountSetupPrompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccountDialog.edit(
        context,
        forced: true,
        onEdit: (value) async {
          context.read<MainBloc>().add(ChangeAccount(value));
        },
      );
    });
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
          } else if (state.status == CommonStatus.success) {
            _maybePromptAccountSetup(context);
          }
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
                                          Text('게이트온 매니저', style: textTheme(context).krTitle2),
                                          const Spacer(),
                                          Text('${state.enterpriseInfo?.name ?? ' '} (${state.enterpriseInfo?.loginId})', style: textTheme(context).krSubtitle1),
                                          const SizedBox(width: 24),
                                          if (AppConfig.to.secureModel.role == Role.ROLE_ADMIN) ...[
                                            InkWell(
                                                onTap: () {
                                                  AccountDialog.edit(context, onEdit: (value) async {
                                                    context.read<MainBloc>().add(ChangeAccount(value));
                                                  });
                                                },
                                                child: Text('아이디/비밀번호 변경', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff7B878D), decoration: TextDecoration.underline))),
                                            const SizedBox(width: 24),
                                          ],
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
