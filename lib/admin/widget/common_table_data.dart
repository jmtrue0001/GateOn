import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommonColumn extends DataColumn {
  final dynamic data;
  final Alignment alignment;
  final double maxWidth;
  final bool isNumber;
  // 고정 폭(px). 지정 시 컬럼을 이 폭으로 고정(필터와 세로 정렬용). null이면 기존(maxWidth 제약)대로.
  final double? width;

  const CommonColumn(this.data, {this.alignment = Alignment.centerLeft, this.maxWidth = double.infinity, this.isNumber = false, this.width}) : super(label: const Text(''));

  @override
  bool get numeric => isNumber;

  @override
  Widget get label => SizedBox(
        width: width,
        child: Container(constraints: BoxConstraints(maxWidth: maxWidth), child: dataWidget(data, alignment: alignment)),
      );
}

class CommonCell extends DataCell {
  final dynamic data;
  final double maxWidth;
  // 고정 폭(px). CommonColumn.width와 동일 값으로 맞춰 사용.
  final double? width;

  const CommonCell(this.data, {this.maxWidth = double.infinity, this.width}) : super(const Text(''));

  @override
  Widget get child => SizedBox(
        width: width,
        child: Container(constraints: BoxConstraints(maxWidth: maxWidth), child: dataWidget(data)),
      );
}

Widget dataWidget(dynamic data, {Alignment alignment = Alignment.centerLeft}) {
  switch (data.runtimeType) {
    case int:
    case double:
      return Align(alignment: Alignment.centerRight, child: Text(NumberFormat('###,###,###,###').format(data), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end));
    case String:
      return Align(alignment: alignment, child: Text(data, maxLines: 2, overflow: TextOverflow.ellipsis));
    case IconButton:
      return Align(alignment: Alignment.centerRight, child: data);
    case bool:
      return Align(alignment: Alignment.centerLeft, child: Icon(data ? Icons.check : Icons.close, color: data ? Colors.green : Colors.red));
    default:
      return const Text('-', maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
