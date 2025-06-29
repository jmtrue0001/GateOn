import 'package:TPASS/admin/sub/widget/sub_dialog.dart';
import 'package:TPASS/admin/widget/list_data_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart' hide Detail;
import '../../widget/admin_widget.dart';
import '../../widget/common_table_data.dart';
import '../bloc/sub_bloc.dart';

class SubPage extends StatelessWidget {
  const SubPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubBloc()..add(const Initial()),
      child: LayoutBuilder(builder: (context, constraints) {
        final bool wideView = constraints.maxWidth > 1400;
        final double width = constraints.maxWidth - 64;
        return BlocConsumer<SubBloc, SubState>(
          listenWhen: (previous, current) => previous.status != current.status || previous.uploadStatus != current.uploadStatus,
          listener: (context, state) {
            switch (state.uploadStatus) {
              case UploadStatus.success:
                Navigator.pop(context);
                showAdaptiveDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog.adaptive(
                        title: const Text(
                          '알림',
                        ),
                        content: Text(
                          '저장되었습니다.',
                          style: textTheme(context).krBody1,
                        ),
                        actions: <Widget>[
                          adaptiveAction(
                            context: context,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('확인'),
                          ),
                        ],
                      );
                    });
                break;
              case UploadStatus.failure:
                showAdaptiveDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog.adaptive(
                        title: const Text(
                          '알림',
                        ),
                        content: Text(
                          '${state.errorMessage}',
                          style: textTheme(context).krBody1,
                        ),
                        actions: <Widget>[
                          adaptiveAction(
                            context: context,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('확인'),
                          ),
                        ],
                      );
                    });
              default:
                break;
            }
          },
          builder: (context, state) {
            return StatsTitleWidget(
              text: '담당 관리자',
              buttons: const [],
              child: Wrap(
                spacing: 32,
                runSpacing: 32,
                children: [
                  if (!state.detail)
                    DataTileContainer(
                      width: width,
                      child: IntrinsicHeight(
                        child: ListDataWidget(
                          title: '담당 관리자 리스트',
                          filterChanged: (value) {
                            context.read<SubBloc>().add(Paginate(page: 1, query: state.query, filterType: value?.$2, orderType: value?.$3));
                          },
                          onPaginate: (page, data) {
                            context.read<SubBloc>().add(Paginate(page: page, query: state.query, filterType: state.filterType, orderType: state.orderType));
                          },
                          onSearch: (data) {
                            context.read<SubBloc>().add(Paginate(page: 1, query: data, filterType: state.filterType, orderType: state.orderType));
                          },
                          meta: state.meta,
                          searchText: state.query,
                          columns: const [
                            CommonColumn('번호', alignment: Alignment.center),
                            CommonColumn('등록일시'),
                            CommonColumn('사용자 이름'),
                            CommonColumn('아이디'),
                          ],
                          filters: const [
                            ("번호 오름차순", FilterType.createdAt, OrderType.desc),
                            ("번호 내림차순", FilterType.disabledAt, OrderType.asc),
                          ],
                          addButton: true,
                          onAdd: () {
                            SubAdminDialog.add(context, onAdd: (value) {
                              context.read<SubBloc>().add(Add(value));
                            });
                          },
                          rows: dataToRows(
                            state.subAdmins,
                            context,
                            !wideView,
                            onClick: (value) {
                              context.read<SubBloc>().add(Detail(value));
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
                                context.read<SubBloc>().add(const Initial());
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
                            Row(
                              children: [
                                Text('담당 관리자 정보', style: textTheme(context).krSubtitle1),
                                const Spacer(),
                                TextButton(
                                    onPressed: () {
                                      SubAdminDialog.edit(context, subAdmin: state.subAdmin, onEdit: (value) {
                                        context.read<SubBloc>().add(Edit(state.subAdmin?.id.toString() ?? '0', value));
                                      });
                                    },
                                    child: Text('정보 변경', style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff7B878D), decoration: TextDecoration.underline))),
                                const SizedBox(width: 32),
                                InkWell(
                                  onTap: () {
                                    showAdaptiveDialog(
                                        context: context,
                                        builder: (ctx) {
                                          return AlertDialog.adaptive(
                                            title: const Text(
                                              '알림',
                                            ),
                                            content: Text(
                                              '관리자를 삭제하시겠습니까?',
                                              style: textTheme(context).krBody1,
                                            ),
                                            actions: <Widget>[
                                              adaptiveAction(
                                                isCancel: true,
                                                context: context,
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('취소'),
                                              ),
                                              adaptiveAction(
                                                context: context,
                                                onPressed: () {
                                                  context.read<SubBloc>().add(Delete(id: state.subAdmin?.id.toString() ?? '0'));
                                                },
                                                child: const Text('확인'),
                                              ),
                                            ],
                                          );
                                        });
                                  },
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: black1,
                                    ),
                                    child: Center(
                                      child: Text('관리자 삭제', style: textTheme(context).krSubtext1B.copyWith(color: white)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                    Text(state.subAdmin?.nickname ?? '', style: textTheme(context).krTitle2),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('아이디', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        Text(state.subAdmin?.username ?? '', style: textTheme(context).krBody2),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('등록 일시', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        Text(timeParser(state.subAdmin?.createdAt, true), style: textTheme(context).krBody2),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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

  List<DataRow> dataToRows(List<SubAdmin> items, BuildContext context, bool isVertical, {required Function(SubAdmin) onClick, Meta? meta}) {
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
                  CommonCell((timeParser(element.value.createdAt, true))),
                  CommonCell(element.value.nickname ?? '-'),
                  CommonCell(element.value.username ?? '-'),
                ]))
        .toList();
  }
}
