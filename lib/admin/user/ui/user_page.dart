import 'package:TPASS/admin/widget/list_data_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../widget/admin_widget.dart';
import '../../widget/common_table_data.dart';
import '../bloc/user_bloc.dart';

class UserPage extends StatelessWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserBloc()..add(const Initial()),
      child: LayoutBuilder(builder: (context, constraints) {
        final bool wideView = constraints.maxWidth > 1400;
        final double width = constraints.maxWidth - 64;
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
                      child: IntrinsicHeight(
                        child: ListDataWidget(
                          title: '방문객 리스트',
                          filterChanged: (value) {
                            context.read<UserBloc>().add(Paginate(page: 1, query: state.query, filterType: value?.$2, orderType: value?.$3));
                          },
                          onPaginate: (page, data) {
                            context.read<UserBloc>().add(Paginate(page: page, query: state.query, filterType: state.filterType, orderType: state.orderType));
                          },
                          onSearch: (data) {
                            context.read<UserBloc>().add(Paginate(page: 1, query: data, filterType: state.filterType, orderType: state.orderType));
                          },
                          meta: state.meta,
                          searchText: state.query,
                          columns: const [
                            CommonColumn('번호', alignment: Alignment.center),
                            CommonColumn('차단일시'),
                            CommonColumn('허용일시'),
                            CommonColumn('유저 디바이스ID'),
                            CommonColumn(
                              '정상 이용여부',
                            ),
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
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('허용/차단 여부', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        Text(state.user?.type ?? '허용', style: textTheme(context).krBody2),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
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
                                        SizedBox(width: 120, child: Text('정상이용여부', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        state.user?.isActive ?? true ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.close, color: Colors.red),
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
                            Container(
                              width: width,
                              constraints: BoxConstraints(maxWidth: width, minHeight: 720, maxHeight: 720),
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
                            ),
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

  List<DataRow> dataToRows(List<User> items, BuildContext context, bool isVertical, {required Function(User) onClick, Meta? meta}) {
    return items
        .asMap()
        .entries
        .map((element) => DataRow(
                onSelectChanged: (selected) {
                  if (selected ?? false) {
                    onClick(element.value);
                  }
                },
                cells: [
                  CommonCell(' ${(meta?.currentPage ?? 1) * (meta?.sizePerPage ?? 20) - (meta?.sizePerPage ?? 20) + element.key + 1}'),
                  CommonCell((timeParser(element.value.disabledAt, true))),
                  CommonCell((timeParser(element.value.enabledAt, true))),
                  CommonCell(element.value.deviceId ?? '-'),
                  CommonCell(element.value.isActive),
                ]))
        .toList();
  }

  List<DataRow> historyToRows(List<History> items, BuildContext context, bool isVertical, {Meta? meta}) {
    return items
        .asMap()
        .entries
        .map((element) => DataRow(cells: [
              CommonCell(' ${(meta?.currentPage ?? 1) * (meta?.sizePerPage ?? 10) - (meta?.sizePerPage ?? 10) + element.key + 1}'),
              CommonCell((timeParser(element.value.createdAt,true))),
              CommonCell((element.value.classification)),
              CommonCell(element.value.way),
              // CommonCell(element.value.nfcInfo),
            ]))
        .toList();
  }
}
