import 'package:TPASS/admin/enterprise/bloc/enterprise_bloc.dart';
import 'package:TPASS/admin/enterprise/widget/enterprise_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../widget/admin_widget.dart';
import '../../widget/common_table_data.dart';
import '../../widget/list_data_widget.dart';

class EnterprisePage extends StatelessWidget {
  const EnterprisePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EnterpriseBloc()..add(const Initial()),
      child: LayoutBuilder(builder: (context, constraints) {
        final bool wideView = constraints.maxWidth > 1400;
        final double width = constraints.maxWidth - 64;
        return BlocConsumer<EnterpriseBloc, EnterpriseState>(
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
              case UploadStatus.delete:
                showAdaptiveDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog.adaptive(
                        title: const Text(
                          '알림',
                        ),
                        content: Text(
                          '삭제되었습니다.',
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
              default:
                break;
            }
          },
          builder: (context, state) {
            return StatsTitleWidget(
              text: '업체 정보',
              buttons: const [],
              child: Wrap(
                spacing: 32,
                runSpacing: 32,
                children: [
                  if (!state.detail)
                    DataTileContainer(
                      width: width,
                      minHeight: 1080,
                      child: IntrinsicHeight(
                        child: ListDataWidget(
                          title: '업체 리스트',
                          filterChanged: (value) {
                            context.read<EnterpriseBloc>().add(Paginate(page: 1, query: state.query, filterType: value?.$2, orderType: value?.$3));
                          },
                          onPaginate: (page, data) {
                            context.read<EnterpriseBloc>().add(Paginate(page: page, query: state.query, filterType: state.filterType, orderType: state.orderType));
                          },
                          onSearch: (data) {
                            context.read<EnterpriseBloc>().add(Paginate(page: 1, query: data, filterType: state.filterType, orderType: state.orderType));
                          },
                          meta: state.meta,
                          searchText: state.query,
                          columns: const [
                            CommonColumn('번호', alignment: Alignment.center),
                            CommonColumn('등록일시'),
                            CommonColumn('업체이름'),
                            CommonColumn('업체아이디'),
                            CommonColumn('업체코드'),
                            CommonColumn('업체주소'),
                          ],
                          filters: const [
                            ("최신 순", FilterType.createdAt, OrderType.desc),
                            ("오래된 순", FilterType.createdAt, OrderType.asc),
                            ("업체 이름 오름차 순", FilterType.name, OrderType.desc),
                            ("업체 이름 내림차 순", FilterType.name, OrderType.asc),
                          ],
                          addButton: true,
                          onAdd: () {
                            EnterpriseDialog.add(
                              context,
                              onChange: () => context.read<EnterpriseBloc>().add(const Initial()),
                              onFilePick: (fileBytes, fileExtension) => context.read<EnterpriseBloc>().add(UploadFile(fileBytes: fileBytes, fileExtension: fileExtension)),
                              onAdd: (data) => context.read<EnterpriseBloc>().add(Add(data)),
                            );
                          },
                          rows: dataToRows(
                            state.enterprises,
                            context,
                            !wideView,
                            meta: state.meta,
                            onClick: (value) {
                              context.read<EnterpriseBloc>().add(DetailEnterprise(enterprise: value));
                            },
                          ),
                        ),
                      ),
                    ),
                  if (state.detail)
                    DataTileContainer(
                      width: width,
                      minHeight: 1080,
                      child: IntrinsicHeight(
                          child: Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                context.read<EnterpriseBloc>().add(const ReInitial());
                              },
                              child: Row(
                                children: [
                                  const SvgImage('assets/icons/ic_arrow_left.svg'),
                                  const SizedBox(width: 8),
                                  Text('목록으로 돌아가기', style: textTheme(context).krSubtext1),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () {
                                      EnterpriseDialog.edit(
                                        context,
                                        enterprise: state.enterprise ?? Enterprise(),
                                        onChange: () => context.read<EnterpriseBloc>().add(const Initial()),
                                        onFilePick: (fileBytes, fileExtension) => context.read<EnterpriseBloc>().add(UploadFile(fileBytes: fileBytes, fileExtension: fileExtension)),
                                        onEdit: (data) => context.read<EnterpriseBloc>().add(Edit('${state.enterprise?.id}', data)),
                                      );
                                    },
                                    child: Container(
                                      width: 88,
                                      decoration: BoxDecoration(
                                        color: blue1,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Center(child: Text('업체 수정', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold))),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                                '업체를 정말로 삭제하시겠습니까?',
                                                style: textTheme(context).krBody1,
                                              ),
                                              actions: <Widget>[
                                                adaptiveAction(
                                                  context: context,
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  isCancel: true,
                                                  child: const Text('취소'),
                                                ),
                                                adaptiveAction(
                                                  context: context,
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    context.read<EnterpriseBloc>().add(Delete(id: state.enterprise?.id.toString() ?? '0'));
                                                  },
                                                  child: const Text('확인'),
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                    child: Container(
                                      width: 88,
                                      decoration: BoxDecoration(
                                        color: black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Center(child: Text('업체 삭제', style: textTheme(context).krSubtext1B.copyWith(color: white, fontWeight: FontWeight.bold))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text('업체 상세정보', style: textTheme(context).krSubtitle1),
                            const SizedBox(height: 40),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 200,
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xffD2D7DD)), borderRadius: BorderRadius.circular(10)),
                                  child: CachedNetworkImage(
                                      imageUrl: '$resourceUrl${state.enterprise?.file?.fileName ?? ''}',
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) {
                                        return Container();
                                      },
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          decoration: const BoxDecoration(
                                            color: white,
                                          ),
                                        );
                                      }),
                                ),
                                const SizedBox(width: 40),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text('${state.enterprise?.name}', style: textTheme(context).krTitle2),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('업체 코드', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        Text(state.enterprise?.code ?? '', style: textTheme(context).krBody2),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        SizedBox(width: 120, child: Text('업체 주소', style: textTheme(context).krBody1.copyWith(color: const Color(0xff999999)))),
                                        Text(state.enterprise?.address ?? '', style: textTheme(context).krBody2),
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
                              child: Center(child: Text('업체 기기 리스트', style: textTheme(context).krSubtitle1.copyWith(color: blue1))),
                            ),
                            const SizedBox(height: 40),
                            Container(
                              width: width,
                              constraints: BoxConstraints(maxWidth: width, minHeight: 720, maxHeight: 720),
                              child: ListDataWidget(
                                outLineBorder: true,
                                title: '업체 기기 리스트',
                                filterChanged: (value) {
                                  context.read<EnterpriseBloc>().add(DetailPaginate(id: state.enterprise?.id.toString(), page: 1, query: state.query, filterType: value?.$2, orderType: value?.$3));
                                },
                                onPaginate: (page, data) {
                                  BlocProvider.of<EnterpriseBloc>(context).add(DetailPaginate(id: state.enterprise?.id.toString(), page: page, query: state.query, filterType: state.filterType, orderType: state.orderType));
                                },
                                onSearch: (data) {
                                  context.read<EnterpriseBloc>().add(DetailPaginate(id: state.enterprise?.id.toString(), page: 1, query: data, filterType: state.filterType, orderType: state.orderType));
                                },
                                meta: state.detailMeta,
                                searchText: state.query,
                                columns: const [
                                  CommonColumn('번호', alignment: Alignment.center),
                                  CommonColumn('등록 일시'),
                                  CommonColumn('구분'),
                                  CommonColumn('방식'),
                                  CommonColumn('기기 정보'),
                                ],
                                filters: const [
                                  ("최신 순", FilterType.createdAt, OrderType.desc),
                                  ("오래된 순", FilterType.createdAt, OrderType.asc),
                                ],
                                rows: deviceDataToRows(
                                  state.devices,
                                  context,
                                  false,
                                  meta: state.detailMeta,
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

  List<DataRow> dataToRows(List<Enterprise> items, BuildContext context, bool isVertical, {required Function(Enterprise) onClick, Meta? meta}) {
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
                  CommonCell(timeParser(element.value.createdAt, true)),
                  CommonCell(element.value.name),
                  CommonCell(element.value.userId),
                  CommonCell(element.value.code),
                  CommonCell(element.value.address),
                ]))
        .toList();
  }

  List<DataRow> deviceDataToRows(List<Device> items, BuildContext context, bool isVertical, {Meta? meta}) {
    return items
        .asMap()
        .entries
        .map((element) => DataRow(cells: [
              CommonCell(' ${(meta?.currentPage ?? 1) * (meta?.sizePerPage ?? 10) - (meta?.sizePerPage ?? 10) + element.key + 1}'),
              CommonCell(timeParser(element.value.createdAt, true)),
              CommonCell(AbleType.strToEnum(element.value.type).data),
              CommonCell(element.value.deviceType),
              CommonCell(element.value.tagId),
            ]))
        .toList();
  }
}
