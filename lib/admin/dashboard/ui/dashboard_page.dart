import 'package:TPASS/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widget/admin_widget.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool wideView = constraints.maxWidth > 1400;
      final double width = (wideView ? constraints.maxWidth - 410 : constraints.maxWidth) - 64;
      final double minHeight = constraints.maxWidth / 2.5;
      return BlocProvider(
        create: (context) => DashboardBloc()..add(const Initial()),
        child: Stack(
          children: [
            Container(margin: const EdgeInsets.all(32), alignment: Alignment.bottomRight, child: Image.asset('assets/images/tpass_background.png')),
            StatsTitleWidget(
              text: '대시보드',
              buttons: const [],
              child: Wrap(
                spacing: 32,
                runSpacing: 32,
                children: [
                  DataTileContainer(
                    height: minHeight,
                    width: width,
                    child: BlocBuilder<DashboardBloc, DashboardState>(
                      buildWhen: (prev, curr) => prev.chartData != curr.chartData,
                      builder: (context, state) {
                        return ChartDataWidget(
                          chartType: state.chartType,
                          onChartTypePick: (chartType) {
                            context.read<DashboardBloc>().add(ChangeChartType(chartType));
                          },
                          onDatePick: (month) {
                            context.read<DashboardBloc>().add(ChangeDate(month));
                          },
                          year: state.year ?? DateTime.now().year,
                          month: state.month ?? DateTime.now().month,
                          title: '방문현황',
                          data: state.chartData,
                        );
                      },
                    ),
                  ),
                  if (wideView)
                    Column(
                      children: [
                        DataTileContainer(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: BlocBuilder<DashboardBloc, DashboardState>(
                              buildWhen: (prev, curr) => prev.allCount != curr.allCount,
                              builder: (context, state) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('누적 방문객 수', style: textTheme(context).krTitle1),
                                    const Spacer(),
                                    Text(
                                      state.allCount.toString(),
                                      style: textTheme(context).krTitle1.copyWith(fontSize: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('명', style: textTheme(context).krBody1)
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        DataTileContainer(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: BlocBuilder<DashboardBloc, DashboardState>(
                              buildWhen: (prev, curr) => prev.todayCount != curr.todayCount,
                              builder: (context, state) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('금일 방문객 수', style: textTheme(context).krTitle1),
                                    const Spacer(),
                                    Text(
                                      state.todayCount.toString(),
                                      style: textTheme(context).krTitle1.copyWith(fontSize: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('명', style: textTheme(context).krBody1)
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        DataTileContainer(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: BlocBuilder<DashboardBloc, DashboardState>(
                              buildWhen: (prev, curr) => prev.disableCount != curr.disableCount,
                              builder: (context, state) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('현재 차단 방문객 수', style: textTheme(context).krTitle1),
                                    const Spacer(),
                                    Text(
                                      state.disableCount.toString(),
                                      style: textTheme(context).krTitle1.copyWith(fontSize: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('명', style: textTheme(context).krBody1)
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        DataTileContainer(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: BlocBuilder<DashboardBloc, DashboardState>(
                              builder: (context, state) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('방문현황', style: textTheme(context).krTitle1),
                                        const Spacer(),
                                        Container(
                                          width: 18,
                                          height: 12,
                                          decoration: const BoxDecoration(color: Color(0xff6FCF97), borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '허용 방문자',
                                          style: textTheme(context).krSubtext2,
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 18,
                                          height: 12,
                                          decoration: const BoxDecoration(color: Color(0xffEB5757), borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '차단 방문자',
                                          style: textTheme(context).krSubtext2,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    LayoutBuilder(builder: (context, constraints) {
                                      return Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(21),
                                          color: const Color(0xffF2F2F2),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                                width: constraints.maxWidth * ((state.todayCount - state.disableCount) / (state.todayCount == 0 ? 1 : state.todayCount * 2)),
                                                constraints: const BoxConstraints(minWidth: 32),
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(21), bottomLeft: Radius.circular(21)),
                                                  color: Color(0xff6FCF97),
                                                ),
                                                child: Center(child: Text('${(state.todayCount - state.disableCount)}', style: textTheme(context).krSubtitle1.copyWith(color: white)))),
                                            Container(
                                                width: constraints.maxWidth * (state.disableCount / (state.todayCount == 0 ? 1 : state.todayCount * 2)),
                                                constraints: const BoxConstraints(minWidth: 32),
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  borderRadius: BorderRadius.only(topRight: Radius.circular(21), bottomRight: Radius.circular(21)),
                                                  color: Color(0xffEB5757),
                                                ),
                                                child: Center(child: Text('${state.disableCount}', style: textTheme(context).krSubtitle1.copyWith(color: white)))),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    Align(alignment: Alignment.centerRight, child: Text('총 ${state.todayCount}명', style: textTheme(context).krBody1))
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (!wideView)
                    Wrap(
                      spacing: 32,
                      runSpacing: 32,
                      children: [
                        DataTileContainer(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: BlocBuilder<DashboardBloc, DashboardState>(
                              buildWhen: (prev, curr) => prev.allCount != curr.allCount,
                              builder: (context, state) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('누적 방문객 수', style: textTheme(context).krTitle1),
                                    const Spacer(),
                                    Text(
                                      state.allCount.toString(),
                                      style: textTheme(context).krTitle1.copyWith(fontSize: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('명', style: textTheme(context).krBody1)
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        DataTileContainer(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: BlocBuilder<DashboardBloc, DashboardState>(
                              buildWhen: (prev, curr) => prev.todayCount != curr.todayCount,
                              builder: (context, state) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('금일 방문객 수', style: textTheme(context).krTitle1),
                                    const Spacer(),
                                    Text(
                                      state.todayCount.toString(),
                                      style: textTheme(context).krTitle1.copyWith(fontSize: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('명', style: textTheme(context).krBody1)
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        DataTileContainer(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: BlocBuilder<DashboardBloc, DashboardState>(
                              buildWhen: (prev, curr) => prev.disableCount != curr.disableCount,
                              builder: (context, state) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('현재 차단 방문객 수', style: textTheme(context).krTitle1),
                                    const Spacer(),
                                    Text(
                                      state.disableCount.toString(),
                                      style: textTheme(context).krTitle1.copyWith(fontSize: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('명', style: textTheme(context).krBody1)
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        DataTileContainer(
                          width: 340,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: BlocBuilder<DashboardBloc, DashboardState>(
                              builder: (context, state) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('방문현황', style: textTheme(context).krTitle1),
                                        const Spacer(),
                                        Container(
                                          width: 18,
                                          height: 12,
                                          decoration: const BoxDecoration(color: Color(0xff6FCF97), borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '허용 방문자',
                                          style: textTheme(context).krSubtext2,
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 18,
                                          height: 12,
                                          decoration: const BoxDecoration(color: Color(0xffEB5757), borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '차단 방문자',
                                          style: textTheme(context).krSubtext2,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    LayoutBuilder(builder: (context, constraints) {
                                      return Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(21),
                                          color: const Color(0xffF2F2F2),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                                width: constraints.maxWidth * ((state.todayCount - state.disableCount) / (state.todayCount == 0 ? 1 : state.todayCount * 2)),
                                                constraints: const BoxConstraints(minWidth: 32),
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(21), bottomLeft: Radius.circular(21)),
                                                  color: Color(0xff6FCF97),
                                                ),
                                                child: Center(child: Text('${(state.todayCount - state.disableCount)}', style: textTheme(context).krSubtitle1.copyWith(color: white)))),
                                            Container(
                                                width: constraints.maxWidth * (state.disableCount / (state.todayCount == 0 ? 1 : state.todayCount * 2)),
                                                constraints: const BoxConstraints(minWidth: 32),
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  borderRadius: BorderRadius.only(topRight: Radius.circular(21), bottomRight: Radius.circular(21)),
                                                  color: Color(0xffEB5757),
                                                ),
                                                child: Center(child: Text('${state.disableCount}', style: textTheme(context).krSubtitle1.copyWith(color: white)))),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    Align(alignment: Alignment.centerRight, child: Text('총 ${state.todayCount}명', style: textTheme(context).krBody1))
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
