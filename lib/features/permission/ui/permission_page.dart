import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../bloc/permission_bloc.dart';
import '../widget/permission_widget.dart';
import '../widget/term_checkbox_widget.dart';

class PermissionPage extends StatelessWidget {
  const PermissionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PermissionBloc()..add(const Initial()),
      child: BlocConsumer<PermissionBloc, PermissionState>(
        listener: (context, state) {
          if (state.status == CommonStatus.success) {
            context.go('/guide');
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: kToolbarHeight,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'logo',
                            child: SvgImage(
                              "assets/images/logo_image_mini.svg",
                              height: 40,
                              color: colorTheme(context).logoColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '접근 권한 안내',
                            style: textTheme(context).krTitle1.copyWith(color: colorTheme(context).primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('필수 접근 권한', style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).titleText)),
                          const SizedBox(height: 16),
                          Text(
                            '필수 접근 권한을 승인하셔야 TPASS의 기능차단 서비스를 이용하실 수 있습니다.',
                            style: textTheme(context).krBody1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          if (defaultTargetPlatform == TargetPlatform.android) const PermissionWidget(permissionType: PermissionType.manager),
                          if (defaultTargetPlatform == TargetPlatform.android) const SizedBox(height: 16),
                          const PermissionWidget(permissionType: PermissionType.camera),
                          const SizedBox(height: 16),
                          const PermissionWidget(permissionType: PermissionType.location),
                          const SizedBox(height: 16),
                          const PermissionWidget(permissionType: PermissionType.bluetooth),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이용약관 및 개인정보 수집 안내',
                            style: textTheme(context).krSubtitle1.copyWith(color: colorTheme(context).titleText),
                          ),
                          const SizedBox(height: 16),
                          TermCheckboxWidget(
                            termType: TermType.privacy,
                            agree: state.privacy,
                            onCheck: (value) {
                              context.read<PermissionBloc>().add(AgreeTerm(value, TermType.privacy));
                            },
                          ),
                          const SizedBox(height: 16),
                          TermCheckboxWidget(
                            termType: TermType.service,
                            agree: state.service,
                            onCheck: (value) {
                              context.read<PermissionBloc>().add(AgreeTerm(value, TermType.service));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: kBottomNavigationBarHeight + 56,
                    )
                  ],
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: InkWell(
              onTap: () {
                if (state.service && state.privacy) {
                  // context.read<PermissionBloc>().add(AgreeAll());
                  context.go('/guide');
                  HapticFeedback.mediumImpact();
                }
              },
              child: Hero(
                tag: 'fab',
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    constraints: const BoxConstraints(maxHeight: 72),
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    decoration: BoxDecoration(color: state.service && state.privacy ? colorTheme(context).activeButton : colorTheme(context).disableButton, borderRadius: BorderRadius.circular(8)),
                    child: SizedBox(
                      child: Center(
                        child: Text(
                          '확인',
                          style: textTheme(context).krTitle2.copyWith(color: state.service && state.privacy ? colorTheme(context).activeTextColor : colorTheme(context).disableTextColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
