import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'popup_menu_widget.dart';

class ListDataWidget<T> extends StatelessWidget {
  const ListDataWidget({
    Key? key,
    required this.title,
    required this.columns,
    this.rows = const [],
    this.onSearch,
    this.meta,
    this.onPaginate,
    this.searchText,
    this.filters = const [],
    this.filterChanged,
    this.showCalender = false,
    this.outLineBorder = false,
    this.addButton = false,
    this.onAdd,
    this.searchVisible = true,
    this.onExcel,
    this.onCount,
  }) : super(key: key);

  final String title;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Function(String)? onSearch;
  final Meta? meta;
  final Function(int, String)? onPaginate;
  final String? searchText;
  final List<T> filters;
  final ValueChanged<T?>? filterChanged;
  final bool showCalender;
  final bool outLineBorder;
  final bool addButton;
  final bool searchVisible;
  final Function()? onAdd;
  final Function()? onExcel;
  final Function(int)? onCount;

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: searchText);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(title, style: textTheme(context).krSubtitle1),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if(onExcel != null)
                  ElevatedButton(
                    // style: ButtonStyle(
                    //   backgroundColor: MaterialStateProperty.all<Color>(Colors.green)
                    // ),
                    onPressed:
                      onExcel
                    ,
                    child: const Text('조회된 로그 저장'),
                  ),
                  const SizedBox(width: 16),
                  if(onCount != null)
                    DropdownButton<int>(
                      value: meta?.sizePerPage,
                      items: [10, 30, 50, 100].map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text('$count 개씩 조회'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          onCount?.call(value); // 기존 onCount 콜백 호출
                        }
                      },
                    ),
                  const SizedBox(width: 16),
                  if (meta != null) Center(child: Text('검색 결과 수 ${meta?.totalCount ?? 0}건', style: textTheme(context).krBody1)),
                  const SizedBox(width: 16),
                  if (searchVisible)SizedBox(
                    width: 340,
                    child: TextFormField(
                        focusNode: FocusNode(),
                        autofocus: false,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLines: 1,
                        minLines: 1,
                        enabled: true,
                        controller: textController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
                          ),
                          hintText: '',
                          counterText: "",
                          filled: false,
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('디바이스ID', style: textTheme(context).krSubtext1.copyWith(color: gray0)),
                                // const SizedBox(width: 32), const Icon(Icons.keyboard_arrow_down, color: gray0)
                              ],
                            ),
                          ),
                          suffixIcon: IconButton(onPressed: () => onSearch?.call(textController.text), icon: const SvgImage('assets/icons/ic_search.svg')),
                          hintStyle: textTheme(context).krBody1.copyWith(color: gray0),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        style: textTheme(context).krBody1,
                        cursorColor: Theme.of(context).primaryColor,
                        onFieldSubmitted: (value) {
                          onSearch?.call(value);
                        }),
                  ),
                  if (filters.isNotEmpty) PopupMenuWidget(dropdownList: filters, onChanged: (value) => filterChanged?.call(value)),
                  if (addButton) InkWell(onTap: () => onAdd?.call(), child: const SvgImage('assets/icons/ic_add.svg')),
                ],
              ),
            ],
          ),
          SizedBox(height: meta == null ? 16 : 40),
          rows.isEmpty
              ? Expanded(
                  child: Center(child: Text("데이터가 없습니다.", style: textTheme(context).krSubtext2.copyWith(fontWeight: FontWeight.bold, fontSize: 16))),
                )
              : Expanded(
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingTextStyle: textTheme(context).krSubtext1,
                    dataTextStyle: textTheme(context).krSubtext1,
                    dividerThickness: 0,
                    sortColumnIndex: 0,
                    horizontalMargin: 0,
                    columnSpacing: 0,
                    showBottomBorder: false,
                    columns: columns,
                    rows: rows,
                  ),
                ),
          const SizedBox(width: 32),
          rows.isEmpty || meta == null
              ? Container()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                        onPressed: () {
                          if (onPaginate != null) {
                            onPaginate!(1, textController.text);
                          }
                        },
                        icon: const Icon(Icons.keyboard_double_arrow_left_outlined)),
                    IconButton(
                        onPressed: () {
                          var page = paginateNumber(meta?.currentPage ?? 1, meta?.totalPages ?? 1, Path.left);
                          if (page != 0) {
                            if (onPaginate != null) {
                              onPaginate!(page, textController.text);
                            }
                          }
                        },
                        icon: const Icon(Icons.keyboard_arrow_left_outlined)),
                    for (int page = getMinPage(meta?.currentPage ?? 1, meta?.totalPages ?? 1); page <= getMaxPage(meta?.currentPage ?? 1, meta?.totalPages ?? 1); page++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextButton(
                            style: TextButton.styleFrom(backgroundColor: page == (meta?.currentPage ?? 1) ? black : white),
                            onPressed: () {
                              if (onPaginate != null) {
                                onPaginate!(page, textController.text);
                              }
                            },
                            child: Text(
                              '$page',
                              style: textTheme(context).krBody1.copyWith(color: page == (meta?.currentPage ?? 1) ? white : black),
                            )),
                      ),
                    IconButton(
                        onPressed: () {
                          var page = paginateNumber(meta?.currentPage ?? 1, meta?.totalPages ?? 1, Path.right);
                          if (page != 0) {
                            if (onPaginate != null) {
                              onPaginate!(page, textController.text);
                            }
                          }
                        },
                        icon: const Icon(Icons.keyboard_arrow_right_outlined)),
                    IconButton(
                        onPressed: () {
                          if (onPaginate != null) {
                            onPaginate!(meta?.totalPages ?? 1, textController.text);
                          }
                        },
                        icon: const Icon(Icons.keyboard_double_arrow_right_outlined)),
                  ],
                )
        ],
      ),
    );
  }

  int getMinPage(int currentPage, int totalPage) {
    if (totalPage <= 5 || currentPage - 2 <= 1) {
      return 1;
    } else {
      if (totalPage - currentPage > 2) {
        return currentPage - 2;
      }
      return currentPage - 4 + (totalPage - currentPage);
    }
  }

  int getMaxPage(int currentPage, int totalPage) {
    if (totalPage <= 5 || currentPage + 2 >= totalPage) {
      return totalPage;
    } else if (currentPage < 3) {
      return 5;
    } else {
      return currentPage + 2;
    }
  }

  int paginateNumber(int currentPage, int totalPage, Path path) {
    switch (path) {
      case Path.left:
        if (currentPage == 1) {
          return 0;
        } else {
          return --currentPage;
        }
      case Path.right:
        if (currentPage == totalPage) {
          return 0;
        } else {
          return ++currentPage;
        }
    }
  }
}
