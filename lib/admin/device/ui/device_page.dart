import 'package:TPASS/admin/device/bloc/device_bloc.dart';
import 'package:TPASS/admin/device/widget/device_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../main.dart';
import '../../widget/admin_widget.dart';
import '../../widget/common_table_data.dart';
import '../../widget/list_data_widget.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceBloc()..add(const Initial()),
      child: LayoutBuilder(builder: (context, constraints) {
        final bool wideView = constraints.maxWidth > 1400;
        final double width = constraints.maxWidth - 64;
        return BlocConsumer<DeviceBloc, DeviceState>(
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
              text: '기기 정보',
              buttons: const [],
              child: Wrap(
                spacing: 32,
                runSpacing: 32,
                children: [
                  DataTileContainer(
                    width: width,
                    minHeight: 1080,
                    child: IntrinsicHeight(
                      child: ListDataWidget(
                        title: '기기 리스트',
                        filterChanged: (value) {
                          context.read<DeviceBloc>().add(Paginate(page: 1, query: state.query, filterType: value?.$2, orderType: value?.$3));
                        },
                        onPaginate: (page, data) {
                          context.read<DeviceBloc>().add(Paginate(page: page, query: state.query, filterType: state.filterType, orderType: state.orderType));
                        },
                        onSearch: (data) {
                          context.read<DeviceBloc>().add(Paginate(page: 1, query: data, filterType: state.filterType, orderType: state.orderType));
                        },
                        meta: state.meta,
                        searchText: state.query,
                        columns: const [
                          CommonColumn('번호', alignment: Alignment.center),
                          CommonColumn('등록일시'),
                          CommonColumn('구분'),
                          CommonColumn('방식'),
                          CommonColumn('일련번호'),
                          // CommonColumn('기기활성화'),

                          CommonColumn(
                            '업체이름',
                          ),
                        ],
                        filters: const [
                          ("등록 최근 순", FilterType.createdAt, OrderType.desc),
                          ("등록 오래된 순", FilterType.createdAt, OrderType.asc),
                        ],
                        rows: dataToRows(
                          state.devices,
                          context,
                          !wideView,
                          meta: state.meta,
                        ),
                        addButton: AppConfig.to.secureModel.role == Role.ROLE_ADMIN,
                        onAdd: () {
                          DeviceDialog.add(context, onAdd: (value) {
                            context.read<DeviceBloc>().add(Add(value));
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  List<DataRow> dataToRows(List<Device> items, BuildContext context, bool isVertical, {Meta? meta}) {
    return items
        .asMap()
        .entries
        .map((element) => DataRow(
                onSelectChanged: (_) {
                  DeviceDialog.edit(context, device: element.value, onEdit: (value) {
                    context.read<DeviceBloc>().add(Edit(element.value.tagId.toString(), value));
                  }, onDelete: () {
                    context.read<DeviceBloc>().add(Delete(id: element.value.tagId.toString()));
                  });
                },
                cells: [
                  CommonCell(' ${(meta?.currentPage ?? 1) * (meta?.sizePerPage ?? 20) - (meta?.sizePerPage ?? 20) + element.key + 1}'),
                  CommonCell(timeParser(element.value.createdAt, true)),
                  CommonCell(AbleType.strToEnum(element.value.type).data),
                  CommonCell(element.value.deviceType),
                  CommonCell(element.value.tagId ?? '-'),
                  // CommonCell(element.value.deviceActive ?? '-'),
                  CommonCell(element.value.enterprise?.name ?? '-'),
                ]))
        .toList();
  }
}
