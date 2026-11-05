import 'package:GateON/admin/widget/list_data_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart' hide Initial;
import '../../widget/admin_widget.dart';
import '../../widget/common_table_data.dart';
import '../bloc/user_bloc.dart';
import '../model/visitor_filter.dart';
import '../widget/visitor_filter_panel.dart';

class UserPage extends StatelessWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserBloc()..add(Initial()),
      child: LayoutBuilder(builder: (context, constraints) {
        final bool wideView = constraints.maxWidth > 1400;
        final double width = constraints.maxWidth - 64;
        // 카드 내부(패딩 24*2 제외) 가용 폭을 비율대로 나눈 컬럼 폭. 테이블·필터가 공유.
        final List<double> colW = visitorColumnWidths(width - 48);
        return BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            return StatsTitleWidget(
              text: '이용자',
              buttons: [
                if (state.detail)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Text(
                      '',
                      style: textTheme(context).krTitle1.copyWith(color: white),
                    ),
                  ),
                if (!state.detail)
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: const Color(0xffEB5757)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: RichText(
                      text: TextSpan(
                        text: '현재 차단된 이용자',
                        style: textTheme(context).krTitle2R.copyWith(color: white),
                        children: <TextSpan>[
                          TextSpan(text: ' ${state.userCount?.disabledCnt ?? 0} ', style: textTheme(context).krTitle1.copyWith(color: white)),
                          TextSpan(text: '명', style: textTheme(context).krTitle2R.copyWith(color: white)),
                        ],
                      ),
                    ),
                  ),
                if (!state.detail) const SizedBox(width: 16),
                if (!state.detail)
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: const Color(0xff6FCF97)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: RichText(
                      text: TextSpan(
                        text: '현재 허용된 이용자',
                        style: textTheme(context).krTitle2R.copyWith(color: white),
                        children: <TextSpan>[
                          TextSpan(text: ' ${state.userCount?.enabledCnt ?? 0} ', style: textTheme(context).krTitle1.copyWith(color: white)),
                          TextSpan(text: '명', style: textTheme(context).krTitle2R.copyWith(color: white)),
                        ],
                      ),
                    ),
                  ),
              ],
              child: Wrap(
                spacing: 32,
                runSpacing: 32,
                children: [
                  if (!state.detail)
                    DataTileContainer(
                      width: width,
                      child: VisitorFilterPanel(
                        colWidths: colW,
                        // 상세 → 복귀 시 패널을 현재 적용 중인 필터로 복원
                        initialFilter: context.read<UserBloc>().currentFilter,
                        onSearch: (filter) {
                          context.read<UserBloc>().add(SearchVisitors(filter: filter, count: state.meta?.sizePerPage));
                        },
                        onReset: () {
                          context.read<UserBloc>().add(SearchVisitors(filter: const VisitorFilter(), count: state.meta?.sizePerPage));
                        },
                      ),
                    ),
                  if (!state.detail)
                    DataTileContainer(
                      width: width,
                      child: IntrinsicHeight(
                        child: ListDataWidget(
                          searchVisible: false,
                          onExcel: (){
                            context.read<UserBloc>().add(ExcelDownload());
                          },
                          title: '방문객 리스트',
                          filterChanged: (value) {
                            context.read<UserBloc>().add(Paginate(page: 1, count: state.meta?.sizePerPage, query: state.query, filterType: value?.$2, orderType: value?.$3));
                          },
                          onPaginate: (page, data) {
                            context.read<UserBloc>().add(Paginate(page: page,count: state.meta?.sizePerPage ,query: state.query, filterType: state.filterType, orderType: state.orderType));
                          },
                          onCount:(count) {
                            context.read<UserBloc>().add(Paginate(page: state.page, count: count,query: state.query, filterType: state.filterType, orderType: state.orderType));
                          },
                          onSearch: (data) {
                            context.read<UserBloc>().add(Paginate(page: 1, count: state.meta?.sizePerPage, query: data, filterType: state.filterType, orderType: state.orderType));
                          },
                          meta: state.meta,
                          searchText: state.query,
                          columns: [
                            CommonColumn('번호', alignment: Alignment.centerLeft, width: colW[0]),
                            CommonColumn('차단일시', width: colW[1]),
                            CommonColumn('허용일시', width: colW[2]),
                            CommonColumn('유저 디바이스ID', width: colW[3]),
                            CommonColumn('제조사', width: colW[4]),
                            CommonColumn('제품명', width: colW[5]),
                            CommonColumn('앱버전', width: colW[6]),
                            CommonColumn('OS 버전', width: colW[7]),
                            CommonColumn('현재 상태', width: colW[8]),
                            CommonColumn('비정상 이력', width: colW[9]),
                          ],
                          filters: const [
                            ("전체 보기", FilterType.disabledAt, OrderType.desc),
                            ("차단일시 최근 순", FilterType.disabledAt, OrderType.desc),
                            ("차단일시 오래된 순", FilterType.disabledAt, OrderType.asc),
                            ("허용일시 최근 순", FilterType.enabledAt, OrderType.desc),
                            ("허용일시 오래된 순", FilterType.enabledAt, OrderType.asc),
                          ],
                          rows: dataToRows(
                            state.users,
                            context,
                            !wideView,
                            colW: colW,
                            onClick: (value) {
                              context.read<UserBloc>().add(Detail(id: value.id.toString()));
                            },
                            meta: state.meta,
                          ),
                        ),
                      ),
                    ),
                  if (state.detail)
                    DataTileContainer(
                      width: width,
                      child: IntrinsicHeight(
                          child: Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                context.read<UserBloc>().add(const ReInitial());
                              },
                              child: Row(
                                children: [
                                  const SvgImage('assets/icons/ic_arrow_left.svg'),
                                  const SizedBox(width: 8),
                                  Text('목록으로 돌아가기', style: textTheme(context).krSubtext1),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text('방문객 상세정보', style: textTheme(context).krSubtitle1),
                            const SizedBox(height: 40),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(padding: const EdgeInsets.all(40), decoration: BoxDecoration(border: Border.all(color: const Color(0xffD2D7DD)), borderRadius: BorderRadius.circular(10)), child: const SvgImage('assets/images/default_profile_image.svg')),
                                const SizedBox(width: 40),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text('방문객', style: textTheme(context).krTitle2),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('디바이스ID', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        Text(state.user?.deviceId ?? '', style: textTheme(context).krBody2),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Row(
                                    //   children: [
                                    //     SizedBox(width: 120, child: Text('허용/차단 여부', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                    //     Text(state.user?.type ?? '허용', style: textTheme(context).krBody2),
                                    //   ],
                                    // ),
                                    // const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('차단 일시', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        Text(timeParser(state.user?.disabledAt, false), style: textTheme(context).krBody2),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('허용 일시', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        Text(timeParser(state.user?.enabledAt, false), style: textTheme(context).krBody2),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('현재 상태', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        // state.user?.isActive ?? true ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.close, color: Colors.red),
                                        Text(typeParser(state.user?.type), style: textTheme(context).krBody2),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Container(
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: blue1, width: 2))),
                              width: 204,
                              padding: const EdgeInsets.all(16),
                              child: Center(child: Text('허용/차단 내역', style: textTheme(context).krSubtitle1.copyWith(color: blue1))),
                            ),
                            const SizedBox(height: 40),
                            Builder(builder: (context) {
                              // 해제 사유가 있는 행은 '담당자/해제사유' 추가 행이 하나 더 붙으므로
                              // 실제 표시 행 수에 맞춰 영역 높이를 늘린다(스크롤 대신 세로로 확장).
                              final displayRows = state.histories.length +
                                  state.histories.where((h) => (h.releaseManager?.isNotEmpty ?? false) || (h.releaseReason?.isNotEmpty ?? false)).length;
                              // 헤더·여백·페이지네이션 등 고정 영역(약 200) + 행당 약 52px, 최소 720 유지
                              final detailHeight = (200 + displayRows * 52).toDouble().clamp(720.0, double.infinity);
                              return Container(
                              width: width,
                              constraints: BoxConstraints(maxWidth: width, minHeight: detailHeight, maxHeight: detailHeight),
                              child: ListDataWidget(
                                outLineBorder: true,
                                title: '허용/차단 내역',
                                filterChanged: (value) {
                                  context.read<UserBloc>().add(DetailPaginate(id: state.user?.id.toString(), page: 1, query: state.query, filterType: value?.$2, orderType: value?.$3));
                                },
                                onPaginate: (page, data) {
                                  // BlocProvider.of<UserBloc>(context).add(DetailPaginate(id: state.user?.id.toString(), page: page, query: state.query, filterType: state.filterType, orderType: state.orderType));
                                  context.read<UserBloc>().add(DetailPaginate(id: state.user?.id.toString(), page: page, query: state.query, filterType: state.filterType, orderType: state.orderType));
                                },
                                onSearch: (data) {
                                  logger.d(data);
                                  context.read<UserBloc>().add(DetailPaginate(id: state.user?.id.toString(), page: 1, query: data, filterType: state.filterType, orderType: state.orderType));
                                },
                                meta: state.detailMeta,
                                searchText: state.query,
                                searchVisible: false,
                                columns: const [
                                  CommonColumn('번호', alignment: Alignment.center),
                                  CommonColumn('일시'),
                                  CommonColumn('구분'),
                                  CommonColumn('방식'),
                                  // CommonColumn(
                                  //   '기기 정보',
                                  // ),
                                ],
                                filters: const [
                                  ("최신 순", FilterType.createdAt, OrderType.desc),
                                  ("오래된 순", FilterType.createdAt, OrderType.asc),
                                  // ("허용 순", FilterType.enabledAt , OrderType.desc),
                                  // ("차단 순", FilterType.disabledAt , OrderType.desc),
                                ],
                                rows: historyToRows(
                                  state.histories,
                                  context,
                                  false,
                                ),
                              ),
                            );
                            }),
                          ],
                        ),
                      )),
                    ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  List<DataRow> dataToRows(List<User> items, BuildContext context, bool isVertical, {required List<double> colW, required Function(User) onClick, Meta? meta}) {
    return items
        .asMap()
        .entries
        .map((element) {
          final status = typeParser(element.value.type);
          final isAbnormal = status == '비정상 사용';
          final textColor = isAbnormal ? Colors.red : null;
          // 비정상 이력 누적 건수 (ABNORMAL만 집계, 없으면 0). 1건 이상이면 빨강 'N회', 없으면 '없음'
          final abnormalCount = element.value.abnormalCount ?? 0;

          return DataRow(
                onSelectChanged: (selected) {
                  if (selected ?? false) {
                    onClick(element.value);
                  }
                },
                cells: [
                  CommonCell('${(meta?.currentPage ?? 1) * (meta?.sizePerPage ?? 20) - (meta?.sizePerPage ?? 20) + element.key + 1}', width: colW[0]),
                  CommonCell((timeParser(element.value.disabledAt, true, second: true)), width: colW[1]),
                  CommonCell((timeParser(element.value.enabledAt, true, second: true)), width: colW[2]),
                  CommonCell(element.value.deviceId ?? '-', width: colW[3]),
                  CommonCell(element.value.osType ?? '-', width: colW[4]),
                  CommonCell(element.value.deviceModel ?? '-', width: colW[5]),
                  CommonCell(element.value.appVersion ?? '-', width: colW[6]),
                  CommonCell(element.value.osVersion ?? '-', width: colW[7]),
                  DataCell(SizedBox(width: colW[8], child: Text(status, style: TextStyle(color: textColor)))),
                  DataCell(SizedBox(
                    width: colW[9],
                    child: Text(
                      abnormalCount > 0 ? '$abnormalCount회' : '없음',
                      style: TextStyle(
                        color: abnormalCount > 0 ? Colors.red : null,
                        fontWeight: abnormalCount > 0 ? FontWeight.w600 : null,
                      ),
                    ),
                  )),
                ]);
        })
        .toList();
  }

  /// 비정상 해제 추가 행의 라벨(담당자/해제 사유) 스타일 — 파란 볼드
  TextStyle _releaseLabelStyle(BuildContext context) =>
      textTheme(context).krSubtext1.copyWith(color: const Color(0xff2F80ED), fontWeight: FontWeight.w600);

  /// 비정상 해제 추가 행의 값 스타일 — 진회색
  TextStyle _releaseValueStyle(BuildContext context) =>
      textTheme(context).krSubtext1.copyWith(color: const Color(0xff444444));

  String _releaseValue(String? v) => (v == null || v.isEmpty) ? '-' : v;

  List<DataRow> historyToRows(List<History> items, BuildContext context, bool isVertical, {Meta? meta}) {
    return items
        .asMap()
        .entries
        .expand((element) {
          final h = element.value;
          final isAbnormal = h.classification == '비정상 사용';
          final textColor = isAbnormal ? Colors.red : null;
          // 비정상 해제 행이면 담당자·사유가 내려온다 → 아래에 별도 한 줄(행)로 표시
          final hasRelease = (h.releaseManager?.isNotEmpty ?? false) || (h.releaseReason?.isNotEmpty ?? false);

          final row = DataRow(cells: [
            CommonCell(' ${(meta?.currentPage ?? 1) * (meta?.sizePerPage ?? 10) - (meta?.sizePerPage ?? 10) + element.key + 1}'),
            CommonCell((timeParser(h.createdAt, true, second: true))),
            DataCell(Text(h.classification ?? '-', style: TextStyle(color: textColor))),
            DataCell(Text(h.way ?? '-', style: TextStyle(color: textColor))),
            // CommonCell(element.value.nfcInfo),
          ]);

          if (!hasRelease) return [row];

          // 담당자·사유 전용 추가 행. 컬럼별로: 번호=담당자, 일시=이름, 구분=해제사유, 방식=내용
          final detailRow = DataRow(
            color: WidgetStateProperty.all(const Color(0xffF5F8FC)),
            cells: [
              DataCell(Text('담당자', style: _releaseLabelStyle(context))),
              DataCell(Text(_releaseValue(h.releaseManager), style: _releaseValueStyle(context), overflow: TextOverflow.ellipsis)),
              DataCell(Text('해제 사유', style: _releaseLabelStyle(context))),
              DataCell(Text(_releaseValue(h.releaseReason), style: _releaseValueStyle(context), overflow: TextOverflow.ellipsis)),
            ],
          );
          return [row, detailRow];
        })
        .toList();
  }
}
